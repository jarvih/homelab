provider "proxmox" {
  endpoint = var.pve_endpoint
  username = var.pve_username # root@pam — required for kvm_arguments (args)
  password = var.pve_password # an API token is NOT accepted for setting VM args
  insecure = var.pve_insecure

  # SSH is used by the provider for file uploads and qcow2 disk imports.
  ssh {
    agent    = true
    username = "root"
  }
}
