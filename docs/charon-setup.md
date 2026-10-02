# Charon VPS

Charon is a SumoPod-resold Tencent Cloud VPS in Singapore: 2 vCPU, 8 GB RAM,
80 GB SSD, delivered with Ubuntu 24.04. It is replaced by NixOS through
`nixos-anywhere`, which **erases the disk**. The account is `hades`, key-only,
with passwordless sudo and no passwords anywhere.

This foundation provides SSH, Tailscale, the host firewall, Docker, swap and
Nix garbage collection. Applications, Caddy and backups are later layers.

## Security model

- Charon is the least trusted machine on the tailnet: it takes internet
  traffic and will run agents fed with untrusted input. Tailscale policy must
  let your devices reach it, never the reverse (luna, laptops).
- After bootstrap, SSH accepts only Tailscale source addresses and port 22 is
  closed on the public interface. Only UDP 41641 (Tailscale) stays open
  until Caddy is added for public sites.
- Docker binds unqualified published ports to `127.0.0.1`. Expose services
  through `tailscale serve` (private) or Caddy (public), not `0.0.0.0`.
- If Tailscale breaks after bootstrap, recovery needs a provider console or
  an OS reinstall from the SumoPod panel. Keep data restorable from backups.

## Step 1: check the Ubuntu VPS

From the Mac, copy the 1Password public key to the delivered account
(usually `ubuntu` or `root`) and inspect the machine:

```bash
ssh-copy-id ubuntu@<public-ip>
ssh ubuntu@<public-ip> 'lsblk -d -o NAME,SIZE,TYPE; [ -d /sys/firmware/efi ] && echo UEFI || echo BIOS; ip -br addr; cat /etc/netplan/*.yaml'
```

Continue only when:

- the 80 GB disk is `vda` (otherwise change `device` in
  `nix/hosts/charon/disko.nix`);
- netplan uses `dhcp4: true` (a static-only network needs a static
  `systemd.network` config in `nix/hosts/charon/hardware.nix` first);
- the delivered user has passwordless sudo or is `root`.

Both BIOS and UEFI boot are supported by the disk layout.

## Step 2: install NixOS

The Mac has no Linux builder, so the system is built on the VPS:

```bash
nix --extra-experimental-features 'nix-command flakes' run github:nix-community/nixos-anywhere -- \
  --flake 'path:/Users/hades/.config/nix#charon' \
  --build-on remote \
  --target-host ubuntu@<public-ip>
```

The VPS reboots into NixOS. The host key changes, so remove the old entry
with `ssh-keygen -R <public-ip>`, then `ssh hades@<public-ip>`.

## Step 3: join the tailnet

In the Tailscale admin console, merge this into the existing policy file
rather than replacing it. If luna or other servers are tagged, keep their
grants. Remove any `"src": ["*"], "dst": ["*"]` rule, which would let charon
reach every device:

```json
"tagOwners": { "tag:vps": ["autogroup:admin"] },
"grants": [
  { "src": ["autogroup:member"], "dst": ["autogroup:self"], "ip": ["*"] },
  { "src": ["autogroup:member"], "dst": ["tag:vps"], "ip": ["*"] }
]
```

Tagged devices do not expire, so charon cannot silently drop off the tailnet.
On charon:

```bash
sudo tailscale up --advertise-tags=tag:vps
```

From the Mac, confirm `ssh hades@charon` works over MagicDNS, and confirm
that `tailscale ping luna` from charon fails.

## Step 4: close public SSH

Set `bootstrapPublicSsh = false` in `nix/hosts/charon/services.nix`, commit
and push, then on charon (over Tailscale):

```bash
git clone https://github.com/nurtantioquidar/nixcfg ~/.config/nix
sudo nixos-rebuild switch --flake ~/.config/nix#charon
```

Keep the current SSH session open and confirm that a new `ssh hades@charon`
works before disconnecting. From outside the tailnet,
`nc -vz <public-ip> 22` must time out. If the SumoPod panel has a firewall,
also allow only UDP 41641 there (and later TCP 80/443).

## Rebuilding

```bash
cd ~/.config/nix && git pull
sudo nixos-rebuild switch --flake ~/.config/nix#charon
```

Validate from the Mac without building:

```bash
nix --extra-experimental-features 'nix-command flakes' eval --raw .#nixosConfigurations.charon.config.system.build.toplevel.drvPath
```

## Backups

Every application keeps its state under `/srv/<app>`. Everything else is
rebuildable from this flake, so restic backs up `/srv` only. It runs daily at
19:00 UTC (02:00 WIB), then prunes to 7 daily, 4 weekly and 6 monthly
snapshots, then verifies 2% of the data. The unit is skipped, not failed,
until all three credential files exist in `/var/lib/secrets/restic/`.

Applications using SQLite must not rely on a plain file copy: give each one
a `backupPrepareCommand` that writes a consistent dump (for example
`sqlite3 db ".backup db.bak"`) into its `/srv/<app>` directory.

### Credentials (once)

1. In Cloudflare, create an R2 bucket `charon-backups`. Then create an R2 API
   token with **Object Read & Write** limited to that bucket, and note its
   access key ID, secret access key, and the S3 endpoint
   `https://<account-id>.r2.cloudflarestorage.com`. Backblaze B2 also works
   through its S3 endpoint.
2. In a terminal (not a chat), create the files on charon. Editing them
   keeps secrets out of shell history:

```bash
ssh -t hades@charon
d=/var/lib/secrets/restic  # root-only directory
for f in repository password env; do sudo install -m 600 /dev/null $d/$f; done
sudo nvim $d/repository  # s3:https://<account-id>.r2.cloudflarestorage.com/charon-backups
head -c 32 /dev/urandom | base64 | sudo tee $d/password >/dev/null
sudo nvim $d/env
```

   `env` contains:

```bash
AWS_ACCESS_KEY_ID=<access key id>
AWS_SECRET_ACCESS_KEY=<secret access key>
AWS_DEFAULT_REGION=auto
```

3. Save the repository URL and the contents of `password`
   (`sudo cat /var/lib/secrets/restic/password`) in 1Password. Without the password the backups
   cannot be restored, and nobody can recover it.

### Running and restoring

```bash
sudo systemctl start restic-backups-offsite   # first run initialises the repository
journalctl -u restic-backups-offsite -e
sudo restic-offsite snapshots
sudo restic-offsite restore latest --target /tmp/restore --include /srv/<app>
```

Test a restore after adding each application.

## Next layers

- Applications as Docker Compose stacks under `/srv/<app>`: AIOStreams and
  Hermes Agent tailnet-only through `tailscale serve`; Hermes uses its Docker
  terminal backend, an allowlisted chat user, and no Docker socket.
- Caddy with TCP 80/443 for monet.sh once its DNS is set up.
- Obsidian: iCloud does not sync to Linux; a vault on charon needs a separate
  sync path such as Syncthing from a Mac.
