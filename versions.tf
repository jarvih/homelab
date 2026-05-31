terraform {
  required_version = ">= 1.6"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
    # Transpiles the fcos 1.5.0 Butane configs to Ignition in-OpenTofu.
    ct = {
      source  = "poseidon/ct"
      version = "~> 0.14"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}
