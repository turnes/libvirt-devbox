locals {
  base_volume_name_input = coalesce(var.base_volume_name, "${local.vm_name}-base")
}

resource "libvirt_volume" "base" {
  count = var.create_base_volume ? 1 : 0

  name = local.base_volume_name_input
  pool = local.storage_pool_name
  target = {
    format = {
      type = "qcow2"
    }
  }
  create = {
    content = {
      url = var.base_image_source
    }
  }
}

locals {
  # The provider has no libvirt_volume data source, so when create_base_volume
  # is false the caller must supply the path from another call's output
  # (e.g. module.first_vm.base_volume_path) via var.base_volume_path.
  base_volume_name = var.create_base_volume ? libvirt_volume.base[0].name : local.base_volume_name_input
  base_volume_path = var.create_base_volume ? libvirt_volume.base[0].path : var.base_volume_path
}

resource "libvirt_volume" "root" {
  name     = "${local.vm_name}-root.qcow2"
  pool     = local.storage_pool_name
  capacity = var.root_disk_size_bytes

  target = { format = { type = "qcow2" } }

  backing_store = {
    path = local.base_volume_path
    format = {
      type = "qcow2"
    }
  }
}
