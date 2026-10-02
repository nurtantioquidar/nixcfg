#!/usr/bin/env bash
# Copy charon's restic credentials and SSH host key into the 1Password item
# that provision.sh reads. Run again after rotating any of them. Values go
# from the host to 1Password through file descriptors and are never printed.
set -euo pipefail

host=${CHARON_HOST:-hades@charon}
vault=${CHARON_OP_VAULT:-Personal}
item=${CHARON_OP_ITEM:-host-secrets__nixos__charon__provision}

remote() { ssh -o BatchMode=yes "$host" "sudo $1"; }
envvar() { remote "sed -n 's/^$1=//p' /var/lib/secrets/restic/env"; }

template=$(jq -n \
  --arg title "$item" \
  --rawfile repo <(remote 'cat /var/lib/secrets/restic/repository') \
  --rawfile password <(remote 'cat /var/lib/secrets/restic/password') \
  --rawfile keyid <(envvar AWS_ACCESS_KEY_ID) \
  --rawfile secret <(envvar AWS_SECRET_ACCESS_KEY) \
  --rawfile hostkey <(remote 'base64 -w0 /etc/ssh/ssh_host_ed25519_key') \
  '
  def field($label; $value): {
    id: $label, label: $label, type: "CONCEALED",
    value: ($value | rtrimstr("\n"))
  };
  {
    title: $title,
    category: "SECURE_NOTE",
    notesPlain: "charon VPS secrets, read by nix/hosts/charon/scripts/provision.sh and written by save-secrets.sh. ssh-host-ed25519-key is base64.",
    fields: [
      field("restic-repository"; $repo),
      field("restic-password"; $password),
      field("r2-access-key-id"; $keyid),
      field("r2-secret-access-key"; $secret),
      field("ssh-host-ed25519-key"; $hostkey)
    ]
  }')

if jq -e '.fields | any(.value == "")' <<<"$template" >/dev/null; then
  echo "a secret read from $host was empty; nothing was saved" >&2
  exit 1
fi

if op item get "$item" --vault "$vault" >/dev/null 2>&1; then
  op item delete "$item" --vault "$vault" --archive
  echo "archived the previous '$item' item in $vault"
fi
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
(umask 077 && printf '%s' "$template" >"$tmp/item.json")
op item create --vault "$vault" --template "$tmp/item.json" --format json | jq -r '"saved \(.title) (\(.fields | length) fields) to \(.vault.name)"'
