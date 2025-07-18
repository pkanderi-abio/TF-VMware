# modules/vm/main.tf
terraform {
  required_providers {
    vsphere = {
      source  = "vmware/vsphere"
      version = ">= 2.13.0"
    }
  }
}

resource "vsphere_virtual_machine" "vm" {
  count            = var.vm_count
  name             = "${var.vm_name_prefix}-${count.index + 1}"
  resource_pool_id = var.resource_pool_id
  datastore_id     = var.datastore_id
  folder           = var.folder_id
  num_cpus         = 2
  memory           = 4096
  guest_id         = var.guest_id
  scsi_type        = var.scsi_type
  firmware         = "efi"
  efi_secure_boot_enabled = true

  # SSH key configuration via guestinfo (cloud-init, key-only)
  extra_config = {
    "guestinfo.userdata" = base64encode(templatefile("${path.module}/cloud-init.yaml", {
      ssh_public_key = var.ssh_public_key
    }))
    "guestinfo.userdata.encoding" = "base64"
  }

  network_interface {
    network_id = var.network_id
  }

  disk {
    label            = "disk0"
    size             = var.disk_size
    thin_provisioned = var.thin_provisioned
  }

  clone {
    template_uuid = var.template_uuid
    customize {
      linux_options {
        host_name = "${var.vm_name_prefix}-${count.index + 1}"
        domain    = "nextgenitcareers.com"
      }
      network_interface {
        ipv4_address = "${var.base_ip_address}.${var.ip_offset + count.index}"
        ipv4_netmask = var.ip_netmask
      }
      ipv4_gateway = var.ip_gateway
      dns_server_list = var.dns_servers
    }
  }

  poweron_timeout = 300 # 5 minutes

  lifecycle {
    prevent_destroy = false
    # Ignore changes to disk size to prevent accidental resizing
    # This is useful if you want to keep the disk size consistent with the template
    # and avoid issues with resizing disks in vSphere.
    # If you need to resize disks, remove this line.
    # Note: This will not prevent changes to the disk size in the template.
    # It only prevents changes to the disk size of the VM created from the template.
    ignore_changes  = [disk]
  }
}

# SSH Setup Provisioner (key-only, with debug)
resource "null_resource" "setup_ssh_keys" {
  count = var.vm_count

  triggers = {
    vm_id = vsphere_virtual_machine.vm[count.index].id
  }

  provisioner "local-exec" {
    command = <<EOT
echo "Setting up SSH keys for VM ${count.index + 1}..."
IP=${vsphere_virtual_machine.vm[count.index].guest_ip_addresses[0]}
KEY=~/.ssh/my-key-pair
USER=ubuntu

# Dynamic wait for SSH (key-only)
echo "Waiting for SSH to be available on $IP..."
for i in {1..30}; do
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -i $KEY $USER@$IP 'echo SSH ready' && break || echo "Attempt $i failed"
  sleep 10
done

if [ $i -eq 30 ]; then
  echo "SSH timed out after 5 minutes. Check cloud-init logs on VM or key in template."
  exit 1
fi

# Attempt to setup SSH key (should succeed if cloud-init worked)
echo "Attempting to setup SSH key..."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $KEY $USER@$IP 'mkdir -p ~/.ssh && echo '${var.ssh_public_key}' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys' && echo "Key setup succeeded" || echo "Key setup failed—check authorized_keys on VM"
EOT
  }
}

# Ansible Provisioner (runs after SSH setup)
resource "null_resource" "ansible_provision" {
  count = var.vm_count

  depends_on = [null_resource.setup_ssh_keys]

  triggers = {
    vm_id = vsphere_virtual_machine.vm[count.index].id
  }

  provisioner "local-exec" {
    command = "ansible-playbook -v -i ${vsphere_virtual_machine.vm[count.index].guest_ip_addresses[0]}, ansible/playbook.yml -u ubuntu --private-key ~/.ssh/my-key-pair --extra-vars \"ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'\""
  }
}