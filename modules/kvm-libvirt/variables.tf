variable "vm_name" {
  type    = string
  default = null
}

variable "vcpu" {
  description = "Number of virtual CPUs."
  type        = number
  default     = 2
}

variable "memory_mib" {
  description = "Memory in MiB."
  type        = number
  default     = 2048
}

variable "root_disk_size_bytes" {
  description = "Size of the VM's root disk, in bytes."
  type        = number
  default     = 21474836480 # 20 GiB
}

variable "vm_ip_address" {
  description = "Static IP address to assign to the VM. Required: an auto-default would collide across VMs sharing a network."
  type        = string
}

variable "vm_mac_address" {
  description = "MAC address to assign to the VM's network interface. If unset, a random locally-administered MAC is generated."
  type        = string
  default     = null
}

variable "network_prefix" {
  description = "CIDR prefix length for the VM's static IP (e.g. 24). Defaults to the effective network CIDR's prefix when unset."
  type        = number
  default     = null
}

variable "gateway" {
  description = "Gateway IP address for the VM's network config. Defaults to the .1 host of the effective network CIDR when unset."
  type        = string
  default     = null
}

variable "dns_servers" {
  description = "DNS servers for the VM's network config."
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "ssh_authorized_keys" {
  description = "SSH public keys authorized to log into the VM. Required: there is no sane shared default."
  type        = list(string)
}

variable "deploy_ssh_key" {
  description = "Path to the SSH private key used to wait for SSH and to run Ansible. Required: there is no sane shared default."
  type        = string
}

variable "cloudinit_user_data_template" {
  description = "Path to a cloud-init user-data .tftpl file."
  type        = string
}

variable "cloudinit_network_config_template" {
  description = "Path to a cloud-init network-config .tftpl file."
  type        = string
}

variable "cloudinit_template_vars" {
  description = "Extra variables passed to both cloud-init templates, merged with the standard ones (user, ssh_authorized_keys, hostname, ip_address, mac_address, gateway, dns_servers, network_prefix)."
  type        = map(any)
  default     = {}
}

variable "create_network" {
  description = "Whether to create the libvirt network. Set to false to reuse an existing one (e.g. created by another module call in the same fleet)."
  type        = bool
  default     = true
}

variable "network_name" {
  description = "Name of the libvirt network. Used as the name to create when create_network is true, or the name of the existing network to use when false. Defaults to \"<vm_name>-network\" when unset."
  type        = string
  default     = null
}

variable "network_cidr" {
  description = "CIDR for the network when create_network is true (e.g. 192.168.122.0/24). Defaults to a randomly chosen 192.168.RANDOM.0/24 when unset."
  type        = string
  default     = null
}

variable "create_storage_pool" {
  description = "Whether to create the libvirt storage pool. Set to false to reuse an existing one."
  type        = bool
  default     = true
}

variable "storage_pool_name" {
  description = "Name of the libvirt storage pool. Used as the name to create when create_storage_pool is true, or the name of the existing pool to use when false. Defaults to \"<vm_name>-pool\" when unset."
  type        = string
  default     = null
}

variable "storage_pool_path" {
  description = "Host filesystem path for the storage pool when create_storage_pool is true. Defaults to \"/var/lib/libvirt/images/<vm_name>\" when unset."
  type        = string
  default     = null
}

variable "create_base_volume" {
  description = "Whether to create the shared base image volume. Set to false to reuse one created by another module call in the same fleet."
  type        = bool
  default     = true
}

variable "base_volume_name" {
  description = "Name of the shared base image volume. Used as the name to create when create_base_volume is true, or the name of the existing volume to use when false. Defaults to \"<vm_name>-base\" when unset."
  type        = string
  default     = null
}

variable "base_image_source" {
  description = "URL or local path to the base cloud image, used when create_base_volume is true."
  type        = string
  default     = null
}

variable "base_volume_path" {
  description = "Host filesystem path of an existing base volume, required when create_base_volume is false (e.g. sourced from another module call's base_volume_path output). The provider has no data source to look this up by name."
  type        = string
  default     = null
}

variable "ansible_playbook_path" {
  description = "Path to the Ansible playbook to run against the VM after boot. Ansible provisioning is skipped entirely when unset."
  type        = string
  default     = null
}

variable "ansible_extra_vars" {
  description = "Extra variables passed to ansible-playbook via --extra-vars."
  type        = map(any)
  default     = {}
}

variable "ansible_user" {
  description = "SSH user Ansible connects as."
  type        = string
  default     = "ubuntu"
}

variable "wait_for_ssh_timeout" {
  description = "Seconds to wait for SSH to become available before running Ansible."
  type        = number
  default     = 300
}

variable "bastion_host" {
  description = "SSH jump host (e.g. the KVM hypervisor) used to reach the VM, for when the VM's network isn't directly routable from wherever Terraform/Ansible runs (e.g. a NAT'd libvirt network on a remote KVM server). Omit to connect to the VM directly."
  type        = string
  default     = null
}

variable "bastion_user" {
  description = "SSH user on the bastion host. Defaults to ansible_user when unset."
  type        = string
  default     = null
}

variable "bastion_ssh_key" {
  description = "SSH private key used to authenticate to the bastion host. Defaults to deploy_ssh_key when unset."
  type        = string
  default     = null
}
