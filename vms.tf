resource "proxmox_virtual_environment_vm" "host" {
  for_each = local.hosts

  name      = each.key
  vm_id     = each.value.vmid
  node_name = each.value.node
  machine   = "q35"

  operating_system { type = "l26" }

  # FCOS ships without qemu-guest-agent, so Proxmox can't talk to it.
  agent { enabled = false }

  # Inject Ignition via QEMU fw_cfg. The comma is the -fw_cfg field separator,
  # so every comma in the rendered JSON must be doubled or the VM won't start.
  kvm_arguments = "-fw_cfg 'name=opt/com.coreos/config,string=${replace(data.ct_config.host[each.key].rendered, ",", ",,")}'"

  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory
  }

  # Import the uploaded FCOS qcow2 as the boot disk.
  disk {
    interface    = "virtio0"
    datastore_id = var.vm_datastore
    file_id      = proxmox_virtual_environment_file.fcos_qcow2.id
    size         = each.value.disk
  }

  network_device {
    bridge = var.bridge
    model  = "virtio"
  }

  # Ignition runs only on first boot; editing a .bu does not re-provision a
  # running VM. To re-provision, destroy and recreate that VM explicitly.
}
