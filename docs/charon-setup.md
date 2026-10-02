# Charon VPS

Charon is an internet-facing NixOS VPS, currently a SumoPod-resold Tencent
Cloud instance in Singapore (2 vCPU, 8 GB RAM, 80 GB SSD). The account is
`hades`, key-only, with passwordless sudo and no passwords anywhere.

The host is disposable: its system comes from this flake, its secrets from
the 1Password item `charon` (personal account, `Personal` vault), and its
application data from the restic repository in R2. `provision.sh` puts all
three onto any fresh KVM VPS.

## Security model

- Charon is the least trusted machine on the tailnet: it takes internet
  traffic and will run agents fed with untrusted input. Tailscale policy must
  let your devices reach it, never the reverse (luna, laptops).
- SSH accepts only Tailscale source addresses and port 22 is closed on the
  public interface. Only UDP 41641 (Tailscale) stays open until Caddy is
  added for public sites.
- Docker binds unqualified published ports to `127.0.0.1`. Expose services
  through `tailscale serve` (private) or Caddy (public), not `0.0.0.0`.
- If Tailscale breaks, recovery means reinstalling the VPS from the provider
  panel and rerunning `provision.sh`; nothing on the host is irreplaceable.

## Tailscale policy (once per tailnet)

In the admin console's Access controls JSON editor:

```json
{
  "tagOwners": { "tag:vps": ["autogroup:admin"] },
  "grants": [
    { "src": ["autogroup:member"], "dst": ["autogroup:self"], "ip": ["*"] },
    { "src": ["autogroup:member"], "dst": ["tag:vps"], "ip": ["*"] }
  ]
}
```

No rule has `tag:vps` as a source, so charon cannot reach your devices.
Tagged devices do not expire. If other servers are tagged, add grants for
them rather than reintroducing an allow-all rule.

## Install or move charon

`nix/hosts/charon/scripts/provision.sh` checks the target, confirms the erase,
stages secrets from 1Password, installs NixOS with `nixos-anywhere` (built on
the target, since the Macs have no Linux builder), waits for charon to join
the tailnet by itself, clones this repo there, and restores `/srv`.

1. **Order a VPS** with a KVM image of any Linux, root or passwordless sudo,
   and DHCP networking. Install your key: `ssh-copy-id root@<ip>` (with
   `SSH_AUTH_SOCK` pointing at the 1Password agent, see below).
2. **When moving**, on the old charon run a final
   `sudo systemctl start restic-backups-offsite`, then delete the old machine
   in the Tailscale admin console so the new one can take the name `charon`.
3. **In the R2 token's client IP filter**, include the new public IP; the
   script prints the VPS's egress IP during its checks.
4. **In Tailscale, generate an auth key** (Settings, Keys): pre-approved,
   tag `tag:vps`, not reusable, not ephemeral, short expiry.
5. **Run in a terminal** (the script prompts):

```bash
nix/hosts/charon/scripts/provision.sh root@<new-public-ip>
```

   Pass `--no-restore` as the second argument for a first install with no
   backups yet. Set `TS_AUTHKEY` to skip the auth-key prompt. Then cancel the
   old VPS.

The SSH host key is restored from 1Password, so `ssh hades@charon` keeps
working without known_hosts changes. If the new provider's disk is not
`/dev/vda`, the script stops; set `disko.devices.disk.main.device` in
`nix/hosts/charon/disko.nix`. A static-only network needs a static
`systemd.network` config in `nix/hosts/charon/hardware.nix` first.

`ssh-copy-id` cannot see 1Password keys by itself:

```bash
SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" \
  ssh-copy-id -o PubkeyAuthentication=no root@<ip>
```

### Secrets in 1Password

`nix/hosts/charon/scripts/save-secrets.sh` copies charon's restic repository,
restic password, R2 keys and SSH host key into the `charon` item without
printing them, archiving any previous version of the item. Rerun it after
rotating any of these. `CHARON_OP_VAULT` and `CHARON_OP_ITEM` override the
vault and item name for both scripts.

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

### Credentials (first setup only)

`provision.sh` restores these from 1Password; this is how they were made.

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

3. Run `nix/hosts/charon/scripts/save-secrets.sh` from the Mac. Without the
   restic password the backups cannot be restored, and nobody can recover it.

### Running and restoring

```bash
sudo systemctl start restic-backups-offsite   # first run initialises the repository
journalctl -u restic-backups-offsite -e
sudo restic-offsite snapshots
sudo restic-offsite restore latest --target /tmp/restore --include /srv/<app>
sudo charon-restore   # whole /srv in place; refuses to overwrite data without --force
```

Applications must be `partOf` and `wantedBy` `charon-apps.target`, so that
`charon-restore` can stop them during a restore and start them again.

Test a restore after adding each application.

## Next layers

- Applications as Docker Compose stacks under `/srv/<app>`: AIOStreams and
  Hermes Agent tailnet-only through `tailscale serve`; Hermes uses its Docker
  terminal backend, an allowlisted chat user, and no Docker socket.
- Caddy with TCP 80/443 for monet.sh once its DNS is set up.
- Obsidian: iCloud does not sync to Linux; a vault on charon needs a separate
  sync path such as Syncthing from a Mac.
