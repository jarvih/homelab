# Transpile each host's Butane config to Ignition, in-OpenTofu.
#
# files_dir points at each host's own directory so its `contents.local:
# quadlets/...` references resolve. The host .bu also carries
# `ignition.config.merge.local: user.ign`, which we strip from the in-memory
# string (ct has a single files_dir and there's no user.ign on disk) and replace
# with the shared user injected as a snippet. The .bu files on disk are
# untouched. The snippet inlines the SSH pubkey from local/id_ed25519.pub so it
# needs no files_dir of its own.
locals {
  merge_block = <<EOT
ignition:
  config:
    merge:
      - local: user.ign
EOT

  ssh_pubkey = trimspace(file("${local.bu_root}/local/id_ed25519.pub"))

  user_snippet = <<-EOT
    variant: fcos
    version: 1.5.0
    passwd:
      users:
        - name: jahe
          ssh_authorized_keys:
            - ${local.ssh_pubkey}
          groups:
            - sudo
  EOT
}

data "ct_config" "host" {
  for_each = local.hosts

  content   = replace(file("${local.bu_root}/${each.key}/${each.key}.bu"), local.merge_block, "")
  strict    = true
  snippets  = [local.user_snippet]
  files_dir = "${local.bu_root}/${each.key}"
}
