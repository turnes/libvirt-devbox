resource "random_integer" "network_octet" {
  count = var.create_network && var.network_cidr == null ? 1 : 0

  min = 0
  max = 255
}

locals {
  network_cidr = var.network_cidr != null ? var.network_cidr : (
    var.create_network ? "192.168.${random_integer.network_octet[0].result}.0/24" : null
  )

  network_name_input = coalesce(var.network_name, "${local.vm_name}-network")

  network_prefix = coalesce(var.network_prefix, local.network_cidr != null ? tonumber(split("/", local.network_cidr)[1]) : null)
  gateway        = coalesce(var.gateway, local.network_cidr != null ? cidrhost(local.network_cidr, 1) : null)
}

resource "libvirt_network" "this" {
  count = var.create_network ? 1 : 0

  name = local.network_name_input

  forward = {
    mode = "nat"
  }

  ips = [
    {
      address = local.gateway
      prefix  = local.network_prefix
      dhcp = {
        ranges = [
          {
            start = cidrhost(local.network_cidr, 2)
            end   = cidrhost(local.network_cidr, 254)
          }
        ]
      }
    }
  ]
}

locals {
  network_name = var.create_network ? libvirt_network.this[0].name : local.network_name_input
}
