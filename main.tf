# main.tf
terraform {
  required_providers {
    vsphere = {
      source  = "vmware/vsphere"
      version = ">= 2.13.0"
    }
  }
}

provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server
  allow_unverified_ssl = true
}

# Variables for provider credentials
variable "vsphere_user" {
  description = "vSphere user name"
  type        = string
}

variable "vsphere_password" {
  description = "vSphere password"
  type        = string
  sensitive   = true
}

variable "vsphere_server" {
  description = "vSphere server address"
  type        = string
}

variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 3
}

variable "ansible_user" {
  description = "SSH user for Ansible access to VMs"
  type        = string
  default     = "ubuntu"  # Default VM user; adjust if different
}

variable "ansible_key_path" {
  description = "Path to SSH private key for Ansible"
  type        = string
  default     = "~/.ssh/my-key-pair"  # Default key path; adjust if different
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  sensitive   = true  # Sensitive to avoid logging
  
}

variable "dns_servers" {
  description = "DNS servers"
  type        = list(string)
  default     = ["192.168.100.1", "8.8.8.8", "8.8.4.4"]

}

variable "ip_offset" {
  description = "Starting offset for last IP octet (e.g., 10 for .10–.12)"
  type        = number
  default     = 10
}

variable "playbook_path" {
  description = "Path to Ansible playbook"
  type        = string
  default     = "ansible/playbook.yml"
}

# Data sources to fetch vSphere resources
data "vsphere_datacenter" "dc" {
  name = "Datacenter"  # Replace with your datacenter name
}

data "vsphere_datastore" "datastore" {
  name          = "LAB-LUN01"  # Replace with your datastore name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = "LAB-CL01"  # Replace with your cluster name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = "LAB-VMs-vLAN_100"  # Replace with your primary network name
  datacenter_id = data.vsphere_datacenter.dc.id
}

# VM Folder
resource "vsphere_folder" "vm_folder" {
  path          = "terraform-vms"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}

# VM Template
data "vsphere_virtual_machine" "template" {
  name          = "ubuntu-template"  # Replace with your template name
  datacenter_id = data.vsphere_datacenter.dc.id
}

# VM Module
# This module creates multiple VMs based on the template
# it uses cloud-init for initial configuration and SSH key injection.
# It also sets up the network and disk configurations.
module "vms" {
  source              = "./modules/vm"
  vm_count            = var.vm_count
  vm_name_prefix      = "terraform-vm"
  template            = data.vsphere_virtual_machine.template.name
  resource_pool_id    = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id        = data.vsphere_datastore.datastore.id
  network_id          = data.vsphere_network.network.id
  template_uuid       = data.vsphere_virtual_machine.template.id
  guest_id            = data.vsphere_virtual_machine.template.guest_id
  scsi_type           = data.vsphere_virtual_machine.template.scsi_type
  folder_id           = vsphere_folder.vm_folder.path
  datacenter_id       = data.vsphere_datacenter.dc.id
  base_ip_address     = "192.168.100"  # Network prefix
  ip_netmask          = 24
  ip_gateway          = "192.168.100.1"  # Adjust to your network
  ip_offset           = var.ip_offset
  dns_servers         = var.dns_servers
  ssh_public_key      = var.ssh_public_key
  disk_size = data.vsphere_virtual_machine.template.disks.0.size # Fixed: Pass disk size from template 
  thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned # Fixed: Pass thin provisioning from template
}

variable "inventory_format" {
  description = "Format for inventory lines (e.g., 'vm_%s ansible_host=%s')"
  type        = string
  default     = "%s"
}

# Local Provisioner to Generate Ansible Inventory (fixed to populate IPv4 IPs)
resource "local_file" "ansible_inventory" {
  content  = join("\n", [for ips in module.vms.vm_ip_addresses : format(var.inventory_format, ips[0], ips[0]) if can(regex("^192\\.168\\.", ips[0]))])
  filename = "${path.module}/ansible_inventory.ini"
}

# Root Outputs (to expose module outputs)
output "vm_ip_addresses" {
  description = "IP addresses of the created VMs"
  value       = module.vms.vm_ip_addresses
}