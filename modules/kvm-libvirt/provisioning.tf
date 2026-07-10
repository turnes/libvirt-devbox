locals {
  ansible_enabled = var.ansible_playbook_path != null

  bastion_user    = coalesce(var.bastion_user, var.ansible_user)
  bastion_ssh_key = coalesce(var.bastion_ssh_key, var.deploy_ssh_key)

  # Reaches the VM by relaying the TCP stream through the bastion; the
  # bastion never needs deploy_ssh_key, only its own bastion_ssh_key.
  ssh_proxy_command = var.bastion_host != null ? "ssh -i ${local.bastion_ssh_key} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p ${local.bastion_user}@${var.bastion_host}" : ""

  vm_ssh_opts = join(" ", compact([
    "-o StrictHostKeyChecking=no",
    "-o UserKnownHostsFile=/dev/null",
    "-o ConnectTimeout=5",
    "-i ${var.deploy_ssh_key}",
    local.ssh_proxy_command != "" ? "-o ProxyCommand=\"${local.ssh_proxy_command}\"" : "",
  ]))
}

resource "local_file" "ansible_inventory" {
  count = local.ansible_enabled ? 1 : 0

  filename = "${path.module}/.generated/${local.vm_name}-inventory.ini"
  content = templatefile("${path.module}/templates/inventory.ini.tftpl", {
    vm_name       = local.vm_name
    ip            = var.vm_ip_address
    ssh_user      = var.ansible_user
    ssh_key       = var.deploy_ssh_key
    proxy_command = local.ssh_proxy_command
  })
}

resource "null_resource" "wait_for_ssh" {
  count = local.ansible_enabled ? 1 : 0

  depends_on = [libvirt_domain.this]

  triggers = {
    vm_id = libvirt_domain.this.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      timeout ${var.wait_for_ssh_timeout} bash -c '
        until ssh ${local.vm_ssh_opts} ${var.ansible_user}@${var.vm_ip_address} true 2>/dev/null; do
          sleep 5
        done
      '
    EOT
  }
}

resource "null_resource" "ansible_provision" {
  count = local.ansible_enabled ? 1 : 0

  depends_on = [null_resource.wait_for_ssh, local_file.ansible_inventory]

  triggers = {
    playbook_hash = filesha256(var.ansible_playbook_path)
    vm_id         = libvirt_domain.this.id
  }

  provisioner "local-exec" {
    command = join(" ", concat(
      ["ansible-playbook", "-i", local_file.ansible_inventory[0].filename, var.ansible_playbook_path],
      length(var.ansible_extra_vars) > 0 ? ["--extra-vars", "'${jsonencode(var.ansible_extra_vars)}'"] : []
    ))
  }
}
