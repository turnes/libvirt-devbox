locals {
  deploy_user = var.ansible_user
}

resource "random_id" "vm_name_suffix" {
  count       = var.vm_name == null ? 1 : 0
  byte_length = 2
}

locals {
  vm_name = var.vm_name != null ? var.vm_name : "vm-${random_id.vm_name_suffix[0].hex}"
}

resource "random_id" "mac_suffix" {
  count       = var.vm_mac_address == null ? 1 : 0
  byte_length = 3
}

locals {
  vm_mac_address = var.vm_mac_address != null ? var.vm_mac_address : join(":", [
    "52", "54", "00",
    substr(random_id.mac_suffix[0].hex, 0, 2),
    substr(random_id.mac_suffix[0].hex, 2, 2),
    substr(random_id.mac_suffix[0].hex, 4, 2),
  ])
}
