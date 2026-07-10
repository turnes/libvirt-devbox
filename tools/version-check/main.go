// version-check compares the *_version defaults pinned in ansible/roles
// against the latest stable release tracked by release-monitoring.org
// (Anitya), and optionally updates the defaults files in place.
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

type roleMapping struct {
	Role       string `json:"role"`
	AnityaID   int    `json:"anitya_id"`
	AnityaName string `json:"anitya_name"`
	Var        string `json:"var"`
	File       string `json:"file"`
}

type anityaProject struct {
	ID             int      `json:"id"`
	StableVersions []string `json:"stable_versions"`
}

type anityaResponse struct {
	Items []anityaProject `json:"items"`
}

type tableRow struct {
	role    string
	current string
	pinned  string
	latest  string
	bumped  bool
}

// processRole compares the on-disk pinned version for m against latest,
// optionally applying the update, and reports whether m was outdated at
// the start of the call (independent of whether apply then fixed it).
func processRole(m roleMapping, latest, repoRoot string, apply bool) (tableRow, bool, error) {
	filePath := filepath.Join(repoRoot, m.File)
	current, err := currentVersion(filePath, m.Var)
	if err != nil {
		return tableRow{}, false, err
	}

	row := tableRow{role: m.Role, current: current, pinned: current, latest: latest}

	if current == latest {
		return row, false, nil
	}

	if apply {
		if err := updateVersion(filePath, m.Var, latest); err != nil {
			return row, true, err
		}
		row.pinned = latest
		row.bumped = true
	}

	return row, true, nil
}

func main() {
	flag.Usage = printHelp

	// Also accept a bare "help" argument (e.g. `version-check help`), not
	// just -h/-help.
	if len(os.Args) > 1 && (os.Args[1] == "help" || os.Args[1] == "-help" || os.Args[1] == "--help") {
		printHelp()
		os.Exit(0)
	}

	mapPath := flag.String("map", "tools/version-check/roles.json", "path to the role -> Anitya project mapping file")
	repoRoot := flag.String("repo-root", ".", "repository root that role file paths in the mapping are relative to")
	token := flag.String("token", "", "Anitya API token (optional; sent as a Bearer token)")
	check := flag.Bool("check", false, "report version drift without modifying any files (default when -apply is not set)")
	apply := flag.Bool("apply", false, "update defaults files where the pinned version is out of date")
	table := flag.String("table", "", "path to write a Markdown table of tracked tool versions (only written when at least one role is outdated and nothing failed)")
	flag.Parse()

	if !*check && !*apply {
		*check = true
	}

	mappings, err := loadMappings(*mapPath)
	if err != nil {
		fatalf("%v", err)
	}

	client := &http.Client{}
	outdated := 0
	failed := 0

	var rows []tableRow

	for _, m := range mappings {
		latest, err := latestStableVersion(client, *token, m)
		if err != nil {
			fmt.Fprintf(os.Stderr, "%-14s ERROR: %v\n", m.Role, err)
			failed++
			continue
		}

		row, isOutdated, err := processRole(m, latest, *repoRoot, *apply)
		if err != nil {
			if isOutdated {
				fmt.Printf("%-14s %-14s -> %-14s outdated\n", m.Role, row.current, row.latest)
				fmt.Fprintf(os.Stderr, "%-14s ERROR applying update: %v\n", m.Role, err)
			} else {
				fmt.Fprintf(os.Stderr, "%-14s ERROR: %v\n", m.Role, err)
			}
			failed++
			continue
		}

		if !isOutdated {
			fmt.Printf("%-14s %-14s up to date\n", m.Role, row.current)
			rows = append(rows, row)
			continue
		}

		outdated++
		fmt.Printf("%-14s %-14s -> %-14s outdated\n", m.Role, row.current, latest)
		if row.bumped {
			fmt.Printf("%-14s updated %s in %s\n", m.Role, m.Var, m.File)
		}
		rows = append(rows, row)
	}

	if failed > 0 {
		os.Exit(2)
	}

	if shouldWriteTable(*table, outdated, failed) {
		if err := writeVersionsTable(*table, rows, time.Now().UTC().Format("2006-01-02")); err != nil {
			fatalf("writing table %s: %v", *table, err)
		}
	}

	if outdated > 0 && !*apply {
		os.Exit(1)
	}
}

func printHelp() {
	fmt.Fprint(flag.CommandLine.Output(), `version-check - compare pinned ansible role versions against Anitya

Compares the *_version defaults pinned in ansible/roles/*/defaults/main.yml
against the latest stable release tracked by release-monitoring.org
(Anitya), and optionally updates the defaults files in place.

Usage:
  version-check [flags]
  version-check help

Flags:
  -check
        Report version drift without modifying any files. This is the
        default when -apply is not given, so it rarely needs to be passed
        explicitly - it exists mainly to be explicit in scripts/CI.

  -apply
        Update the pinned *_version value in each defaults/main.yml file
        whose current value doesn't match the latest stable version on
        Anitya. Only the matched "key: value" line is rewritten - comments,
        other keys, and formatting are left untouched. Files that are
        already up to date are left alone.

  -token string
        Anitya API token. Optional: anonymous requests work fine against
        the public read endpoints this tool uses. When set, it's sent as
        an "Authorization: Bearer <token>" header.

  -map string
        Path to the role -> Anitya project mapping file (JSON).
        (default "tools/version-check/roles.json")

  -repo-root string
        Repository root that the "file" path in each mapping entry is
        resolved relative to. (default ".")

  -table string
        Path to write a Markdown table of tracked tool versions (e.g.
        VERSIONS.md). Only written when at least one role was outdated
        and no role failed to check. Unset by default, in which case no
        table is written.

Exit codes:
  0   success (either -apply ran cleanly, or -check found nothing outdated)
  1   -check found outdated versions (nothing was modified)
  2   an error occurred (bad mapping file, network failure, file I/O, etc.)

Examples:
  # From the repository root: report drift, change nothing.
  version-check -check

  # Update every outdated defaults/main.yml in place.
  version-check -apply

  # Use an Anitya API token, and a mapping file/repo root elsewhere.
  version-check -apply -token "$ANITYA_TOKEN" -map ./roles.json -repo-root ..
`)
}

func fatalf(format string, args ...any) {
	fmt.Fprintf(os.Stderr, format+"\n", args...)
	os.Exit(2)
}

func loadMappings(mapPath string) ([]roleMapping, error) {
	data, err := os.ReadFile(mapPath)
	if err != nil {
		return nil, fmt.Errorf("reading mapping file %s: %w", mapPath, err)
	}
	var mappings []roleMapping
	if err := json.Unmarshal(data, &mappings); err != nil {
		return nil, fmt.Errorf("parsing mapping file %s: %w", mapPath, err)
	}
	return mappings, nil
}

// latestStableVersion looks up an Anitya project by name and returns the
// newest entry in stable_versions - not the raw "version" field, which can
// be an alpha/rc/pre-release (e.g. Terraform's "version" is routinely a
// dev alpha build while stable_versions[0] is the actual latest release).
func latestStableVersion(client *http.Client, token string, m roleMapping) (string, error) {
	q := url.Values{}
	q.Set("name", m.AnityaName)
	q.Set("items_per_page", "250")
	reqURL := "https://release-monitoring.org/api/v2/projects/?" + q.Encode()

	req, err := http.NewRequest(http.MethodGet, reqURL, nil)
	if err != nil {
		return "", err
	}
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}

	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("querying anitya: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("anitya returned %s: %s", resp.Status, string(body))
	}

	var parsed anityaResponse
	if err := json.NewDecoder(resp.Body).Decode(&parsed); err != nil {
		return "", fmt.Errorf("decoding anitya response: %w", err)
	}

	for _, item := range parsed.Items {
		if item.ID == m.AnityaID {
			if len(item.StableVersions) == 0 {
				return "", fmt.Errorf("anitya project %d (%s) has no stable_versions", m.AnityaID, m.AnityaName)
			}
			return item.StableVersions[0], nil
		}
	}
	return "", fmt.Errorf("anitya project id %d not found under name %q", m.AnityaID, m.AnityaName)
}

func versionLineRegexp(varName string) *regexp.Regexp {
	// [ \t] rather than \s: \s also matches \n, and since $ (in multiline
	// mode) matches both before a \n and at the absolute end of the
	// string, a greedy \s* would consume the trailing newline itself,
	// which ReplaceAll would then drop from the file.
	return regexp.MustCompile(`(?m)^(` + regexp.QuoteMeta(varName) + `:[ \t]*)"?([^"\n]+?)"?[ \t]*$`)
}

func currentVersion(filePath, varName string) (string, error) {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return "", fmt.Errorf("reading %s: %w", filePath, err)
	}
	match := versionLineRegexp(varName).FindSubmatch(data)
	if match == nil {
		return "", fmt.Errorf("%s: no %q key found", filePath, varName)
	}
	return string(match[2]), nil
}

// updateVersion rewrites only the matched "<var>: value" line in place,
// leaving the rest of the file (comments, other keys, formatting) untouched.
func updateVersion(filePath, varName, newVersion string) error {
	data, err := os.ReadFile(filePath)
	if err != nil {
		return fmt.Errorf("reading %s: %w", filePath, err)
	}
	re := versionLineRegexp(varName)
	if !re.Match(data) {
		return fmt.Errorf("%s: no %q key found", filePath, varName)
	}
	updated := re.ReplaceAll(data, []byte(`${1}"`+newVersion+`"`))
	if err := os.WriteFile(filePath, updated, 0o644); err != nil {
		return fmt.Errorf("writing %s: %w", filePath, err)
	}
	return nil
}

func writeVersionsTable(path string, rows []tableRow, checkedDate string) error {
	var b strings.Builder
	b.WriteString("| Role | Pinned version | Latest upstream | Status | Last checked |\n")
	b.WriteString("| --- | --- | --- | --- | --- |\n")
	for _, r := range rows {
		status := "✅ up to date"
		if r.bumped {
			status = fmt.Sprintf("⬆️ bumped (was %s)", r.current)
		} else if r.pinned != r.latest {
			status = "⚠️ outdated"
		}
		fmt.Fprintf(&b, "| %s | %s | %s | %s | %s |\n", r.role, r.pinned, r.latest, status, checkedDate)
	}
	return os.WriteFile(path, []byte(b.String()), 0o644)
}

// shouldWriteTable reports whether the versions table should be (re)written
// for this run: only when a table path was given, nothing failed, and at
// least one role was outdated.
func shouldWriteTable(tablePath string, outdated, failed int) bool {
	return tablePath != "" && failed == 0 && outdated > 0
}
