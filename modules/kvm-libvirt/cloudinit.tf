resource "libvirt_cloudinit_disk" "this" {
  name = "${local.vm_name}-cloudinit.iso"

  user_data = templatefile(var.cloudinit_user_data_template, merge({
    user                = local.deploy_user
    ssh_authorized_keys = var.ssh_authorized_keys
    hostname            = local.vm_name
  }, var.cloudinit_template_vars))

  meta_data = yamlencode({
    instance-id    = local.vm_name
    local-hostname = local.vm_name
  })

  network_config = templatefile(var.cloudinit_network_config_template, merge({
    ip_address  = var.vm_ip_address
    prefix      = local.network_prefix
    mac_address = local.vm_mac_address
    gateway     = local.gateway
    dns_servers = var.dns_servers
  }, var.cloudinit_template_vars))
}

resource "libvirt_volume" "cloudinit" {
  name = "${local.vm_name}-cloudinit"
  pool = local.storage_pool_name

  target = {
    format = {
      type = "iso"
    }
  }

  create = {
    content = {
      url = libvirt_cloudinit_disk.this.path
    }
  }

  lifecycle {
    replace_triggered_by = [libvirt_cloudinit_disk.this]
  }
}
