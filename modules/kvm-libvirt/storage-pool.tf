locals {
  storage_pool_name_input = coalesce(var.storage_pool_name, "${local.vm_name}-pool")
  storage_pool_path       = coalesce(var.storage_pool_path, "/var/lib/libvirt/images/${local.vm_name}")
}

resource "libvirt_pool" "this" {
  count = var.create_storage_pool ? 1 : 0

  name = local.storage_pool_name_input
  type = "dir"
  target = {
    path = local.storage_pool_path
  }
}

locals {
  storage_pool_name = var.create_storage_pool ? libvirt_pool.this[0].name : local.storage_pool_name_input
}
