variable "pve_endpoint" {
  description = "Proxmox VE API endpoint, e.g. https://pve1.example.lan:8006/"
  type        = string
}

variable "pve_username" {
  description = "Proxmox user. Must be root@pam — kvm_arguments is root-only."
  type        = string
  default     = "root@pam"
}

variable "pve_password" {
  description = "Password for pve_username."
  type        = string
  sensitive   = true
}

variable "pve_insecure" {
  description = "Skip TLS verification (self-signed PVE certificate)."
  type        = bool
  default     = true
}

variable "image_node" {
  description = "Node the FCOS qcow2 image is uploaded to."
  type        = string
}

variable "image_datastore" {
  description = "Datastore (iso content) that holds the uploaded FCOS image."
  type        = string
  default     = "local"
}

variable "vm_datastore" {
  description = "Datastore for VM disks."
  type        = string
  default     = "local-lvm"
}

variable "bridge" {
  description = "Network bridge for the VM NIC."
  type        = string
  default     = "vmbr0"
}

variable "fcos_stream" {
  description = "Fedora CoreOS stream: stable, testing, or next."
  type        = string
  default     = "stable"
}

variable "fcos_arch" {
  description = "Fedora CoreOS architecture."
  type        = string
  default     = "x86_64"
}
