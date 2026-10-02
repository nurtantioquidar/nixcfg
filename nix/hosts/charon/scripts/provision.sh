#!/usr/bin/env bash
# Install charon onto a fresh VPS, ERASING its disk, then restore /srv from
# the latest off-site backup. See "Install or move charon" in
# docs/charon-setup.md.
#
#   nix/hosts/charon/scripts/provision.sh <user@new-public-ip> [--no-restore]
#
# Secrets come from the 1Password item written by save-secrets.sh. The
# Tailscale auth key is read from TS_AUTHKEY or prompted for.
set -euo pipefail

target=${1:?usage: provision.sh <user@new-public-ip> [--no-restore]}
restore=${2:-}
vault=${CHARON_OP_VAULT:-Personal}
item=${CHARON_OP_ITEM:-host-secrets__nixos__charon__provision}
repo=https://github.com/nurtantioquidar/nixcfg
flake=$(cd "$(dirname "$0")/../../../.." && pwd)
ip=${target#*@}

nixx() { nix --extra-experimental-features 'nix-command flakes' "$@"; }
ref() { printf 'op://%s/%s/%s' "$vault" "$item" "$1"; }

disk=$(nixx eval --raw "$flake#nixosConfigurations.charon.config.disko.devices.disk.main.device")

echo "== Checking $target"
ssh -o StrictHostKeyChecking=accept-new "$target" '
  lsblk -d -o NAME,SIZE,TYPE
  [ -d /sys/firmware/efi ] && echo "boot: UEFI" || echo "boot: BIOS"
  ip -br -4 addr
  echo "egress IPv4: $(curl -4 -s --max-time 10 https://ifconfig.me)"'
# shellcheck disable=SC2029 # $disk is meant to expand locally
if ! ssh "$target" "test -b $disk"; then
  echo "$disk does not exist there; set disko.devices.disk.main.device in nix/hosts/charon/disko.nix" >&2
  exit 1
fi
if ! ssh "$target" '[ "$(id -u)" = 0 ] || sudo -n true'; then
  echo "$target needs root or passwordless sudo" >&2
  exit 1
fi
op read "$(ref restic-repository)" >/dev/null

cat <<EOF

Before continuing, confirm:
  1. Old charon (if any) had a final backup and was removed in the
     Tailscale admin console, so the new machine can take the name.
  2. The R2 token's client IP filter includes the egress IP above.
  3. $disk on $ip will be ERASED.

EOF
read -rp "Type $ip to continue: " answer
[ "$answer" = "$ip" ] || { echo "aborted" >&2; exit 1; }

if [ -z "${TS_AUTHKEY:-}" ]; then
  read -rsp "Tailscale auth key (tag:vps, pre-approved, single-use): " TS_AUTHKEY
  echo
fi
case $TS_AUTHKEY in
  tskey-auth-*) ;;
  *) echo "that is not a Tailscale auth key" >&2; exit 1 ;;
esac

stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
umask 077
secrets=$stage/var/lib/secrets
mkdir -p "$secrets/restic" "$secrets/tailscale" "$stage/etc/ssh"
chmod 755 "$stage/var" "$stage/var/lib" "$stage/etc" "$stage/etc/ssh"

op read "$(ref restic-repository)" >"$secrets/restic/repository"
op read "$(ref restic-password)" >"$secrets/restic/password"
{
  printf 'AWS_ACCESS_KEY_ID=%s\n' "$(op read "$(ref r2-access-key-id)")"
  printf 'AWS_SECRET_ACCESS_KEY=%s\n' "$(op read "$(ref r2-secret-access-key)")"
  printf 'AWS_DEFAULT_REGION=auto\n'
} >"$secrets/restic/env"
printf '%s' "$TS_AUTHKEY" >"$secrets/tailscale/authkey"

hostkey=$stage/etc/ssh/ssh_host_ed25519_key
op read "$(ref ssh-host-ed25519-key)" | base64 --decode >"$hostkey"
ssh-keygen -y -f "$hostkey" >"$hostkey.pub"
chmod 644 "$hostkey.pub"

echo "== Installing NixOS (this erases $disk)"
nixx run github:nix-community/nixos-anywhere -- \
  --flake "$flake#charon" \
  --build-on remote \
  --extra-files "$stage" \
  --target-host "$target"

echo "== Waiting for charon on the tailnet"
for _ in $(seq 1 60); do
  ssh -o BatchMode=yes -o ConnectTimeout=5 hades@charon true 2>/dev/null && break
  sleep 10
done
egress=$(ssh -o BatchMode=yes hades@charon 'curl -4 -s --max-time 10 https://ifconfig.me')
if [ "$egress" != "$ip" ]; then
  echo "'charon' on the tailnet answers from $egress, not $ip: is the old machine still listed?" >&2
  exit 1
fi

ssh -o BatchMode=yes hades@charon "[ -d ~/.config/nix/.git ] || git clone -q $repo ~/.config/nix"

if [ "$restore" != "--no-restore" ]; then
  echo "== Restoring /srv from the latest snapshot"
  ssh -o BatchMode=yes hades@charon 'sudo charon-restore && sudo restic-offsite snapshots --latest 1'
fi

echo "== Done: ssh hades@charon"
