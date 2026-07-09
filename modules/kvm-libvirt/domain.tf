resource "libvirt_domain" "this" {
  name        = local.vm_name
  memory      = var.memory_mib
  memory_unit = "MiB"
  vcpu        = var.vcpu
  type        = "kvm"

  running = true

  autostart = true

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
    boot_devices = [
      { "dev" = "hd" },
      { "dev" = "network" }
    ]
  }

  cpu = {
    mode = "host-passthrough"
  }


  devices = {
    disks = [
      {
        source = {
          volume = {
            pool   = libvirt_volume.root.pool
            volume = libvirt_volume.root.name
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
        driver = {
          type = "qcow2"
        }
      },
      {
        device = "cdrom"
        source = {
          file = {
            pool = libvirt_volume.cloudinit.pool
            file = libvirt_volume.cloudinit.path
          }
        }
        target = {
          dev = "sda"
          bus = "sata"
        }
      }
    ]

    interfaces = [
      {
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = local.network_name
          }
        }
        mac = {
          address = local.vm_mac_address
        }
      }
    ]

    consoles = [{
      type = "pty"
      source = {
        path = "/dev/pts/0"
      }
      target = {
        type = "serial"
        # port omitted - let libvirt handle it
      }
      },
      {
        type = "pty"
        source = {
          path = "/dev/pts/1"
        }
        target = {
          type = "virtio"
          # port omitted - let libvirt handle it
        }
      },
    ]
    channels = [
      {
        source = {
          unix = {}
        }
        target = {
          virt_io = {
            name = "org.qemu.guest_agent.0"
          }
        }
      }
    ]
  }


}
