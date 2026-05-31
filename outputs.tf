output "vms" {
  description = "Provisioned CoreOS VMs (name => id/node/mac)."
  value = {
    for k, vm in proxmox_virtual_environment_vm.host : k => {
      vm_id = vm.vm_id
      node  = vm.node_name
      mac   = try(vm.mac_addresses[0], null)
    }
  }
}

# Handy for DHCP reservations: host => MAC. No guest agent needed — the MAC is
# generated at create time (IPs would require qemu-guest-agent, which FCOS lacks).
output "mac_addresses" {
  description = "Each VM's primary NIC MAC address."
  value = {
    for k, vm in proxmox_virtual_environment_vm.host : k => try(vm.mac_addresses[0], null)
  }
}
