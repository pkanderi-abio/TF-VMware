# modules/vm/variables.tf
variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 1
}

variable "vm_name_prefix" {
  description = "Prefix for VM names"
  type        = string
  default     = "terraform-vm"
}

variable "resource_pool_id" {
  description = "Resource pool ID"
  type        = string
}

variable "datastore_id" {
  description = "Datastore ID"
  type        = string
}

variable "network_id" {
  description = "Network ID"
  type        = string
}

variable "template_uuid" {
  description = "Template UUID"
  type        = string
}

variable "guest_id" {
  description = "Guest ID"
  type        = string
}

variable "scsi_type" {
  description = "SCSI type"
  type        = string
}

variable "folder_id" {
  description = "Folder ID"
  type        = string
}

variable "datacenter_id" {
  description = "Datacenter ID"
  type        = string
}

variable "base_ip_address" {
  description = "Base IP address (e.g., 192.168.100)"
  type        = string
}

variable "ip_netmask" {
  description = "IP netmask"
  type        = number
  default     = 24
}

variable "ip_gateway" {
  description = "IP gateway"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key content"
  type        = string
}

variable "template" {
  description = "Template name"
  type        = string
}

variable "disk_size" {
  description = "Disk size"
  type        = number
}

variable "thin_provisioned" {
  description = "Thin provisioned"
  type        = bool
}

variable "ansible_user" {
  description = "Ansible SSH user"
  type        = string
  default     = "ubuntu"
}

variable "ansible_key_path" {
  description = "Ansible SSH key path"
  type        = string
  default     = "~/.ssh/my-key-pair"
}

variable "dns_servers" {
  description = "DNS servers"
  type        = list(string)
  default     = ["192.168.100.1", "8.8.8.8", "8.8.4.4"]
}

variable "ip_offset" {
  description = "Starting offset for last IP octet"
  type        = number
}

variable "playbook_path" {
  description = "Path to Ansible playbook"
  type        = string
  default     = "ansible/playbook.yml"
}