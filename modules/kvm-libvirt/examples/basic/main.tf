terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

module "vm_1" {
  source = "../.."

  vm_name        = "example-1"
  vm_ip_address  = "192.168.122.10"
  vm_mac_address = "52:54:00:00:00:10"
  network_prefix = 24
  gateway        = "192.168.122.1"
  dns_servers    = ["192.168.122.1"]

  ssh_authorized_keys = ["ssh-ed25519 AAAA...replace-with-your-key... you@example"]
  deploy_ssh_key      = "~/.ssh/id_ed25519"

  cloudinit_user_data_template      = "${path.module}/templates/user_data.yml.tftpl"
  cloudinit_network_config_template = "${path.module}/templates/netplan.yml.tftpl"

  create_network = true
  network_name   = "example-net"
  network_cidr   = "192.168.122.0/24"

  create_storage_pool = true
  storage_pool_name   = "example-pool"
  storage_pool_path   = "/var/lib/libvirt/images/example"

  create_base_volume = true
  base_volume_name   = "ubuntu-22.04-base"
  base_image_source  = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"

  ansible_playbook_path = "${path.module}/ansible/playbook.yml"
}

module "vm_2" {
  source = "../.."

  vm_name       = "example-2"
  vm_ip_address = "192.168.122.11"
  # vm_mac_address omitted: the module generates a random one
  network_prefix = 24
  gateway        = "192.168.122.1"
  dns_servers    = ["192.168.122.1"]

  ssh_authorized_keys = ["ssh-ed25519 AAAA...replace-with-your-key... you@example"]
  deploy_ssh_key      = "~/.ssh/id_ed25519"

  cloudinit_user_data_template      = "${path.module}/templates/user_data.yml.tftpl"
  cloudinit_network_config_template = "${path.module}/templates/netplan.yml.tftpl"

  create_network = false
  network_name   = module.vm_1.network_name

  create_storage_pool = false
  storage_pool_name   = module.vm_1.storage_pool_name

  create_base_volume = false
  base_volume_name   = module.vm_1.base_volume_name
  base_volume_path   = module.vm_1.base_volume_path

  ansible_playbook_path = "${path.module}/ansible/playbook.yml"
}
