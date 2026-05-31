# Transpile each host's Butane config to Ignition, in-OpenTofu.
#
# The host .bu files keep their `ignition.config.merge.local: user.ign` line on
# disk, but we strip that block from the in-memory string before handing it to
# ct (otherwise ct would try to read a user.ign file that isn't there) and merge
# the shared user via a snippet instead. files_dir resolves the snippet's
# id_ed25519.pub. Result: the jahe user ends up on every host, with no generated
# files, no local_file resource, and no first-apply ordering problem.
locals {
  merge_block = <<EOT
ignition:
  config:
    merge:
      - local: user.ign
EOT
}

data "ct_config" "host" {
  for_each = local.hosts

  content   = replace(file("${local.bu_root}/${each.key}/${each.key}.bu"), local.merge_block, "")
  strict    = true
  snippets  = [file("${local.bu_root}/local/user.bu")]
  files_dir = "${local.bu_root}/local"
}
