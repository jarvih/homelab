# The PVE download_file API rejects a raw *.qcow2.xz ("wrong file extension"),
# so fetch + decompress locally, then upload the plain image as iso content.
# coreos-installer picks the correct build for the chosen stream/arch.
resource "null_resource" "fcos_qcow2" {
  triggers = {
    stream = var.fcos_stream
    arch   = var.fcos_arch
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      mkdir -p "${path.module}/.image"
      rm -f "${path.module}/.image/fedora-coreos.qcow2.img"
      f=$(coreos-installer download -p qemu -f qcow2.xz \
            -s ${var.fcos_stream} -a ${var.fcos_arch} \
            -C "${path.module}/.image")
      xz -df "$f"
      mv "$${f%.xz}" "${path.module}/.image/fedora-coreos.qcow2.img"
    EOT
  }
}

resource "proxmox_virtual_environment_file" "fcos_qcow2" {
  content_type = "iso"
  datastore_id = var.image_datastore
  node_name    = var.image_node

  source_file {
    path = "${path.module}/.image/fedora-coreos.qcow2.img"
  }

  depends_on = [null_resource.fcos_qcow2]
}
