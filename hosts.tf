locals {
  # One entry per CoreOS host. Each maps to ../coreOS-configs/<name>/<name>.bu
  hosts = {
    #controller = { vmid = 9001, node = "lenovo-proxmox1", cores = 2, memory = 2048, disk = 32 }
    #ns1        = { vmid = 9002, node = "lenovo-proxmox1", cores = 1, memory = 1024, disk = 20 }
    netbox = { vmid = 9004, node = "lenovo-proxmox1", cores = 2, memory = 4096, disk = 32 }
  }

  # Butane (.bu) source configs, now vendored under this repo.
  bu_root = "${path.module}/coreOS-configs"
}
