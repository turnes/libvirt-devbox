terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu+ssh://rafael@172.22.1.202/system?known_hosts_verify=ignore"
}

module "vm_1" {
  source = "../../modules/kvm-libvirt"

  vm_name        = "devops"
  vm_ip_address  = "192.168.88.10"
  network_prefix = 24
  gateway        = "192.168.88.1"
  dns_servers    = ["1.1.1.1", "8.8.8.8"]

  ssh_authorized_keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFD3KdEo8YloEiTj0PpevKXRHJCpPqk6poq1emvi9tm9 rafael.turnes@pop-os"]
  deploy_ssh_key      = "~/.ssh/amora-default"
  bastion_host = "172.22.1.202"
  bastion_user = "rafael"

  cloudinit_user_data_template      = "${path.module}/templates/user_data.yml.tftpl"
  cloudinit_network_config_template = "${path.module}/templates/netplan.yml.tftpl"

  create_network = true
  network_name   = "devops"
  network_cidr   = "192.168.88.0/24"

  create_storage_pool = true
  storage_pool_name   = "devops"

  create_base_volume = true
  base_volume_name   = "ubuntu-26.04-base"
  base_image_source  = "../resolute-server-cloudimg-amd64.img"

  ansible_playbook_path = "${path.module}/ansible/playbook.yml"
}