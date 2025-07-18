# modules/vm/outputs.tf
output "vm_ip_addresses" {
  description = "IP addresses of the created VMs"
  value       = [for vm in vsphere_virtual_machine.vm : vm.guest_ip_addresses]
}

output "vm_names" {
  description = "Names of the created VMs"
  value       = [for vm in vsphere_virtual_machine.vm : vm.name]
}

output "vm_ids" {
  description = "IDs of the created VMs"
  value       = [for vm in vsphere_virtual_machine.vm : vm.id]
}