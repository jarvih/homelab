# CoreOS on Proxmox (OpenTofu)

Declaratively deploys Fedora CoreOS (FCOS) VMs to a Proxmox cluster, using the
Butane configs vendored under [`coreOS-configs/`](coreOS-configs).

## How Ignition reaches the VM

Proxmox's cloud-init does **not** understand Ignition. FCOS reads its config from
a QEMU `fw_cfg` device at `opt/com.coreos/config`. So:

1. `data "ct_config"` (poseidon/ct) transpiles each `coreOS-configs/<host>/<host>.bu`
   to Ignition JSON in-OpenTofu, with `files_dir` set to that host's dir so its
   `contents.local: quadlets/...` references resolve. The shared user is merged
   in as a snippet built in `ignition.tf`. (fcos 1.5.0 — poseidon/ct v0.14 does
   not support 1.6.0.)
2. The JSON is passed inline through the VM's QEMU `args`:
   `-fw_cfg 'name=opt/com.coreos/config,string=<rendered>'`.
   Commas are doubled (`,` → `,,`) because comma is the `-fw_cfg` separator.
3. The FCOS qcow2 image is fetched, decompressed, and uploaded as the boot disk.

## Prerequisites

- `tofu` (or `terraform`) >= 1.6
- `coreos-installer` and `xz` on the machine running `tofu apply`
  (used by `image.tf` to fetch/decompress the qcow2)
- **`root@pam` password auth** to Proxmox — an API token is rejected for setting
  VM `args`.
- SSH access to the Proxmox node (`ssh { agent = true }` in `providers.tf`) for
  image upload / disk import. Make sure `ssh-add -l` shows your key.

- `coreOS-configs/local/id_ed25519.pub` — the SSH pubkey for the `jahe` user.
  `ignition.tf` reads it and inlines it into the user snippet
  (e.g. `cp ~/.ssh/id_ed25519.pub coreOS-configs/local/`).

No butane/podman is needed — Ignition is transpiled in-OpenTofu.

## Usage

```sh
cp terraform.tfvars.example terraform.tfvars   # then edit
tofu init

# Bring up one host first to validate end-to-end:
tofu apply -target='proxmox_virtual_environment_vm.host["dns"]'

# Then the rest:
tofu apply
```

## Hosts

Edit `local.hosts` in `hosts.tf` (vmid / node / cores / memory / disk per host).

## Notes

- **Ignition is first-boot only.** Editing a `.bu` does NOT re-provision a
  running VM (the new Ignition is ignored on reboot); you'll see a cosmetic
  `kvm_arguments` diff. To re-provision, destroy + recreate that VM:
  `tofu apply -replace='proxmox_virtual_environment_vm.host["dns"]'`.
- **No guest agent.** Proxmox won't report the VM's IP — use the MAC from
  `tofu output mac_addresses` for a DHCP reservation. (IPs would need
  qemu-guest-agent, which FCOS lacks.)
- **Butane spec is 1.5.0.** The configs were downgraded from 1.6.0 (which only
  added s390x-specific features they don't use) so poseidon/ct v0.14 can
  transpile them.
- **User / `merge.local` handling.** Host `.bu` files keep their
  `merge.local: user.ign` line on disk, but `ignition.tf` strips it from the
  in-memory string (ct's single `files_dir` already points at the host dir for
  `quadlets/`) and injects the `jahe` user via a snippet defined in
  `ignition.tf`, which inlines the pubkey from `coreOS-configs/local/id_ed25519.pub`.
  So `coreOS-configs/local/user.bu` is **not** read by the deploy — to change the
  user, edit `local.user_snippet` in `ignition.tf`.
- **Large configs.** If a rendered config outgrows the `args` length limit,
  switch to the snippet `file=` delivery (upload the `.ign` as a `snippets` file
  and point `fw_cfg` at `/var/lib/vz/snippets/<host>.ign`).
