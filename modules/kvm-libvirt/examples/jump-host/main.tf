terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

# The KVM server is a separate machine, reachable only over SSH: the
# provider itself talks to libvirt through that same SSH connection.
provider "libvirt" {
  uri = "qemu+ssh://devops@kvm-host.example.com/system?keyfile=~/.ssh/id_ed25519&known_hosts_verify=ignore"
}

module "vm" {
  source = "../.."

  vm_name       = "devops-tools"
  vm_ip_address = "192.168.122.10"
  network_cidr  = "192.168.122.0/24"

  ssh_authorized_keys = ["ssh-ed25519 AAAA...replace-with-your-key... you@example"]
  deploy_ssh_key      = "~/.ssh/id_ed25519"

  cloudinit_user_data_template      = "${path.module}/templates/user_data.yml.tftpl"
  cloudinit_network_config_template = "${path.module}/templates/netplan.yml.tftpl"

  base_image_source = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"

  # The VM lives on a NAT'd libvirt network on the remote KVM host, so
  # wait_for_ssh and ansible-playbook (run from wherever `terraform apply`
  # runs) can only reach it by hopping through that same host.
  bastion_host = "kvm-host.example.com"
  bastion_user = "devops"
  # bastion_ssh_key omitted: defaults to deploy_ssh_key, which is also
  # authorized on the KVM host in this example.

  ansible_playbook_path = "${path.module}/ansible/playbook.yml"
}
