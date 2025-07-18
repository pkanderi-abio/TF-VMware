# Terraform + VMware Project README.md

```markdown
# TF-VMware: Terraform Automation for VMware vSphere VMs

This repository uses Terraform to provision virtual machines (VMs) in a VMware vSphere environment. It clones VMs from an Ubuntu template, configures networking (static IPs, DNS, gateway), sets up SSH key access via cloud-init, and uses Ansible for post-provisioning (e.g., installing Nginx). The project is modular, with a root `main.tf` and a VM module in `modules/vm/`.

## Features
- Provisions 3 VMs (configurable) in a custom folder (`terraform-vms`).
- Uses existing vSphere resources (datastore: LAB-LUN01, cluster: LAB-CL01, network: LAB-VMs-vLAN_100).
- Customizes VMs with static IPs (e.g., 192.168.100.10–.12), domain (nextgenitcareers.com), and DNS servers.
- Enables key-only SSH access via cloud-init.
- Runs Ansible playbook to install and start Nginx on VMs.
- Outputs VM IPs for easy access.

## Prerequisites
- **vSphere Environment**: Access to vCenter with administrator privileges (user, password, server in `terraform.tfvars`).
- **Ubuntu Template**: An Ubuntu VM template named "ubuntu-template" with cloud-init installed (for customization and SSH setup).
- **Terraform**: Version >= 1.0 installed.
- **Ansible**: Installed on your local machine (for post-provisioning).
- **SSH Key Pair**: Generate a key pair (e.g., `ssh-keygen -t rsa -f ~/.ssh/my-key-pair`) and add the public key to `terraform.tfvars` or `main.tf`.
- **Git**: Clone this repo.

## Setup
1. **Clone the Repository**:
   ```
   git clone <your-repo-url>
   cd TF-VMware
   ```

2. **Update `terraform.tfvars`**:
   - Edit `terraform.tfvars` with your vSphere credentials and optional overrides (e.g., vm_count, ssh_public_key).
     ```
     vsphere_user     = "Administrator@vsphere.local"
     vsphere_password = "your-password"
     vsphere_server   = "<vCenterName/IP Address>"
     ssh_public_key   = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD... your-public-key-here"
     ```

3. **Initialize Terraform**:
   ```
   terraform init
   ```

4. **Preview the Plan**:
   ```
   terraform plan
   ```

5. **Apply the Configuration**:
   ```
   terraform apply
   ```
   - Type `yes` to confirm. This provisions the VMs, sets up SSH, and runs Ansible to install Nginx.

## Usage
- **Customize Variables**: Edit `main.tf` or `terraform.tfvars` for changes (e.g., vm_count = 5, base_ip_address = "192.168.100").
- **Outputs**: After apply, run `terraform output vm_ip_addresses` to get VM IPs.
- **SSH Access**: SSH to VMs with your key: `ssh -i ~/.ssh/my-key-pair ubuntu@<vm-ip>`.
- **Check Nginx**: On a VM, run `systemctl status nginx` or curl the IP to see the default page.
- **Ansible Playbook**: The playbook in `ansible/playbook.yml` installs Nginx—edit for more tasks.

## Cleanup
1. **Destroy Resources**:
   ```
   terraform destroy
   ```
   - Type `yes` to confirm. This deletes the VMs and folder.

2. **Manual Cleanup**: If needed, delete the folder in vCenter.

## Troubleshooting
- **SSH Connection Fails**: Check cloud-init logs on VM (`/var/log/cloud-init-output.log`).
- **Ansible UNREACHABLE**: Increase sleep in provisioner or verify IPs.
- **Invalid IPs**: Adjust `base_ip_address` and `ip_offset` in variables.

## License
MIT License. See LICENSE for details.

## Acknowledgments
- Built with Terraform and the VMware vSphere provider.
- Ansible for post-provisioning.

Feel free to contribute or open issues!
```
