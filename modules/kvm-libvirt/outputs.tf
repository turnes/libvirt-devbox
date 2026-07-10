output "vm_name" {
  value = libvirt_domain.this.name
}

output "vm_ip_address" {
  value = var.vm_ip_address
}

output "network_name" {
  description = "Resolved network name, whether created by this call or reused from an existing one."
  value       = local.network_name
}

output "storage_pool_name" {
  description = "Resolved storage pool name, whether created by this call or reused from an existing one."
  value       = local.storage_pool_name
}

output "base_volume_name" {
  description = "Resolved base volume name, whether created by this call or reused from an existing one."
  value       = local.base_volume_name
}

output "base_volume_path" {
  description = "Resolved base volume host path. Pass this as base_volume_path to other module calls that set create_base_volume = false."
  value       = local.base_volume_path
}

output "cloud_init" {
  description = "Cloud init rendered"
  value = libvirt_cloudinit_disk.this
}

output "cloud_init-volume" {
  description = "Cloud init rendered"
  value = libvirt_volume.cloudinit
}

output "domain" {
  description = "Cloud init rendered"
  value = libvirt_domain.this
}