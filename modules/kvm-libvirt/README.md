# kvm-libvirt

Terraform module that provisions a single KVM virtual machine via the [dmacvicar/libvirt](https://registry.terraform.io/providers/dmacvicar/libvirt/latest) provider: a libvirt network, storage pool, base cloud image, a root disk backed by that image, and a cloud-init disk to configure the guest on first boot. Optionally waits for SSH and runs an Ansible playbook against the VM once it's up.

Network, storage pool, and base image can each be created by this module call or reused from another one — this lets multiple VMs share a network/pool/base image within the same fleet without re-downloading or re-declaring them.

## Usage

```hcl
module "vm" {
  source = "../../modules/kvm-libvirt"

  vm_ip_address = "192.168.122.10"
  network_cidr  = "192.168.122.0/24"

  ssh_authorized_keys = ["ssh-ed25519 AAAA... you@example"]
  deploy_ssh_key      = "~/.ssh/id_ed25519"

  cloudinit_user_data_template      = "${path.module}/templates/user_data.yml.tftpl"
  cloudinit_network_config_template = "${path.module}/templates/netplan.yml.tftpl"

  base_image_source = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
}
```

See [examples/](examples/) for complete, runnable configurations:

- **[minimal](examples/minimal/)** — smallest viable config; everything besides the IP/network is left to generated defaults.
- **[basic](examples/basic/)** — two VMs, where the second reuses the first's network, storage pool, and base image instead of creating its own.
- **[jump-host](examples/jump-host/)** — VM on a remote KVM host reached only over SSH, provisioned through a bastion since its libvirt network isn't directly routable.


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6 |
| <a name="requirement_libvirt"></a> [libvirt](#requirement\_libvirt) | 0.9.8 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_libvirt"></a> [libvirt](#provider\_libvirt) | 0.9.8 |
| <a name="provider_local"></a> [local](#provider\_local) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [libvirt_cloudinit_disk.this](https://registry.terraform.io/providers/dmacvicar/libvirt/0.9.8/docs/resources/cloudinit_disk) | resource |
| [libvirt_domain.this](https://registry.terraform.io/providers/dmacvicar/libvirt/0.9.8/docs/resources/domain) | resource |
| [libvirt_network.this](https://registry.terraform.io/providers/dmacvicar/libvirt/0.9.8/docs/resources/network) | resource |
| [libvirt_pool.this](https://registry.terraform.io/providers/dmacvicar/libvirt/0.9.8/docs/resources/pool) | resource |
| [libvirt_volume.base](https://registry.terraform.io/providers/dmacvicar/libvirt/0.9.8/docs/resources/volume) | resource |
| [libvirt_volume.cloudinit](https://registry.terraform.io/providers/dmacvicar/libvirt/0.9.8/docs/resources/volume) | resource |
| [libvirt_volume.root](https://registry.terraform.io/providers/dmacvicar/libvirt/0.9.8/docs/resources/volume) | resource |
| [local_file.ansible_inventory](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [null_resource.ansible_provision](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.wait_for_ssh](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_id.mac_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_id.vm_name_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_integer.network_octet](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_ansible_extra_vars"></a> [ansible\_extra\_vars](#input\_ansible\_extra\_vars) | Extra variables passed to ansible-playbook via --extra-vars. | `map(any)` | `{}` | no |
| <a name="input_ansible_playbook_path"></a> [ansible\_playbook\_path](#input\_ansible\_playbook\_path) | Path to the Ansible playbook to run against the VM after boot. Ansible provisioning is skipped entirely when unset. | `string` | `null` | no |
| <a name="input_ansible_user"></a> [ansible\_user](#input\_ansible\_user) | SSH user Ansible connects as. | `string` | `"ubuntu"` | no |
| <a name="input_base_image_source"></a> [base\_image\_source](#input\_base\_image\_source) | URL or local path to the base cloud image, used when create\_base\_volume is true. | `string` | `null` | no |
| <a name="input_base_volume_name"></a> [base\_volume\_name](#input\_base\_volume\_name) | Name of the shared base image volume. Used as the name to create when create\_base\_volume is true, or the name of the existing volume to use when false. Defaults to "<vm\_name>-base" when unset. | `string` | `null` | no |
| <a name="input_base_volume_path"></a> [base\_volume\_path](#input\_base\_volume\_path) | Host filesystem path of an existing base volume, required when create\_base\_volume is false (e.g. sourced from another module call's base\_volume\_path output). The provider has no data source to look this up by name. | `string` | `null` | no |
| <a name="input_bastion_host"></a> [bastion\_host](#input\_bastion\_host) | SSH jump host (e.g. the KVM hypervisor) used to reach the VM, for when the VM's network isn't directly routable from wherever Terraform/Ansible runs (e.g. a NAT'd libvirt network on a remote KVM server). Omit to connect to the VM directly. | `string` | `null` | no |
| <a name="input_bastion_ssh_key"></a> [bastion\_ssh\_key](#input\_bastion\_ssh\_key) | SSH private key used to authenticate to the bastion host. Defaults to deploy\_ssh\_key when unset. | `string` | `null` | no |
| <a name="input_bastion_user"></a> [bastion\_user](#input\_bastion\_user) | SSH user on the bastion host. Defaults to ansible\_user when unset. | `string` | `null` | no |
| <a name="input_cloudinit_network_config_template"></a> [cloudinit\_network\_config\_template](#input\_cloudinit\_network\_config\_template) | Path to a cloud-init network-config .tftpl file. | `string` | n/a | yes |
| <a name="input_cloudinit_template_vars"></a> [cloudinit\_template\_vars](#input\_cloudinit\_template\_vars) | Extra variables passed to both cloud-init templates, merged with the standard ones (user, ssh\_authorized\_keys, hostname, ip\_address, mac\_address, gateway, dns\_servers, network\_prefix). | `map(any)` | `{}` | no |
| <a name="input_cloudinit_user_data_template"></a> [cloudinit\_user\_data\_template](#input\_cloudinit\_user\_data\_template) | Path to a cloud-init user-data .tftpl file. | `string` | n/a | yes |
| <a name="input_create_base_volume"></a> [create\_base\_volume](#input\_create\_base\_volume) | Whether to create the shared base image volume. Set to false to reuse one created by another module call in the same fleet. | `bool` | `true` | no |
| <a name="input_create_network"></a> [create\_network](#input\_create\_network) | Whether to create the libvirt network. Set to false to reuse an existing one (e.g. created by another module call in the same fleet). | `bool` | `true` | no |
| <a name="input_create_storage_pool"></a> [create\_storage\_pool](#input\_create\_storage\_pool) | Whether to create the libvirt storage pool. Set to false to reuse an existing one. | `bool` | `true` | no |
| <a name="input_deploy_ssh_key"></a> [deploy\_ssh\_key](#input\_deploy\_ssh\_key) | Path to the SSH private key used to wait for SSH and to run Ansible. Required: there is no sane shared default. | `string` | n/a | yes |
| <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers) | DNS servers for the VM's network config. | `list(string)` | <pre>[<br/>  "1.1.1.1",<br/>  "8.8.8.8"<br/>]</pre> | no |
| <a name="input_gateway"></a> [gateway](#input\_gateway) | Gateway IP address for the VM's network config. Defaults to the .1 host of the effective network CIDR when unset. | `string` | `null` | no |
| <a name="input_memory_mib"></a> [memory\_mib](#input\_memory\_mib) | Memory in MiB. | `number` | `2048` | no |
| <a name="input_network_cidr"></a> [network\_cidr](#input\_network\_cidr) | CIDR for the network when create\_network is true (e.g. 192.168.122.0/24). Defaults to a randomly chosen 192.168.RANDOM.0/24 when unset. | `string` | `null` | no |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | Name of the libvirt network. Used as the name to create when create\_network is true, or the name of the existing network to use when false. Defaults to "<vm\_name>-network" when unset. | `string` | `null` | no |
| <a name="input_network_prefix"></a> [network\_prefix](#input\_network\_prefix) | CIDR prefix length for the VM's static IP (e.g. 24). Defaults to the effective network CIDR's prefix when unset. | `number` | `null` | no |
| <a name="input_root_disk_size_bytes"></a> [root\_disk\_size\_bytes](#input\_root\_disk\_size\_bytes) | Size of the VM's root disk, in bytes. | `number` | `21474836480` | no |
| <a name="input_ssh_authorized_keys"></a> [ssh\_authorized\_keys](#input\_ssh\_authorized\_keys) | SSH public keys authorized to log into the VM. Required: there is no sane shared default. | `list(string)` | n/a | yes |
| <a name="input_storage_pool_name"></a> [storage\_pool\_name](#input\_storage\_pool\_name) | Name of the libvirt storage pool. Used as the name to create when create\_storage\_pool is true, or the name of the existing pool to use when false. Defaults to "<vm\_name>-pool" when unset. | `string` | `null` | no |
| <a name="input_storage_pool_path"></a> [storage\_pool\_path](#input\_storage\_pool\_path) | Host filesystem path for the storage pool when create\_storage\_pool is true. Defaults to "/var/lib/libvirt/images/<vm\_name>" when unset. | `string` | `null` | no |
| <a name="input_vcpu"></a> [vcpu](#input\_vcpu) | Number of virtual CPUs. | `number` | `2` | no |
| <a name="input_vm_ip_address"></a> [vm\_ip\_address](#input\_vm\_ip\_address) | Static IP address to assign to the VM. Required: an auto-default would collide across VMs sharing a network. | `string` | n/a | yes |
| <a name="input_vm_mac_address"></a> [vm\_mac\_address](#input\_vm\_mac\_address) | MAC address to assign to the VM's network interface. If unset, a random locally-administered MAC is generated. | `string` | `null` | no |
| <a name="input_vm_name"></a> [vm\_name](#input\_vm\_name) | n/a | `string` | `null` | no |
| <a name="input_wait_for_ssh_timeout"></a> [wait\_for\_ssh\_timeout](#input\_wait\_for\_ssh\_timeout) | Seconds to wait for SSH to become available before running Ansible. | `number` | `300` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_base_volume_name"></a> [base\_volume\_name](#output\_base\_volume\_name) | Resolved base volume name, whether created by this call or reused from an existing one. |
| <a name="output_base_volume_path"></a> [base\_volume\_path](#output\_base\_volume\_path) | Resolved base volume host path. Pass this as base\_volume\_path to other module calls that set create\_base\_volume = false. |
| <a name="output_cloud_init"></a> [cloud\_init](#output\_cloud\_init) | Cloud init rendered |
| <a name="output_cloud_init-volume"></a> [cloud\_init-volume](#output\_cloud\_init-volume) | Cloud init rendered |
| <a name="output_domain"></a> [domain](#output\_domain) | Cloud init rendered |
| <a name="output_network_name"></a> [network\_name](#output\_network\_name) | Resolved network name, whether created by this call or reused from an existing one. |
| <a name="output_storage_pool_name"></a> [storage\_pool\_name](#output\_storage\_pool\_name) | Resolved storage pool name, whether created by this call or reused from an existing one. |
| <a name="output_vm_ip_address"></a> [vm\_ip\_address](#output\_vm\_ip\_address) | n/a |
| <a name="output_vm_name"></a> [vm\_name](#output\_vm\_name) | n/a |
<!-- END_TF_DOCS -->