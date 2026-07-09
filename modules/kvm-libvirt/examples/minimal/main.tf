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

module "vm" {
  source = "../.."

  # Everything else (vm_name, vm_mac_address, network_name,
  # storage_pool_name, storage_pool_path, base_volume_name, ansible
  # provisioning) falls back to a sensible generated default.
  #
  # vm_ip_address has no default (it would collide across VMs sharing a
  # network), so network_cidr is pinned here too, to guarantee the IP
  # actually falls inside it.

  ssh_authorized_keys = ["ssh-ed25519 AAAA...replace-with-your-key... you@example"]
  deploy_ssh_key      = "~/.ssh/id_ed25519"

  cloudinit_user_data_template      = "${path.module}/templates/user_data.yml.tftpl"
  cloudinit_network_config_template = "${path.module}/templates/netplan.yml.tftpl"

  network_cidr  = "192.168.122.0/24"
  vm_ip_address = "192.168.122.10"

  base_image_source = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
}
