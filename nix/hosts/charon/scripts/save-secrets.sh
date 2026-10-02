#!/usr/bin/env bash
# Copy charon's secrets into the 1Password item that provision.sh reads: the
# restic credentials, the SSH host key, and every application env file
# /var/lib/secrets/<app>/env (one section per app, one field per variable,
# labels in kebab-case). Run again after adding or rotating any of them.
# Values travel through pipes and private temp files, never arguments or
# output.
set -euo pipefail

host=${CHARON_HOST:-hades@charon}
vault=${CHARON_OP_VAULT:-Personal}
item=${CHARON_OP_ITEM:-host-secrets__nixos__charon__provision}

remote() { ssh -o BatchMode=yes "$host" "sudo $1"; }
envvar() { remote "sed -n 's/^$1=//p' /var/lib/secrets/restic/env"; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
umask 077

: >"$tmp/apps.jsonl"
for app in $(remote 'find /var/lib/secrets -mindepth 2 -maxdepth 2 -name env ! -path "*/restic/*"' | xargs -r -n1 dirname | xargs -r -n1 basename); do
  jq -c --arg app "$app" -R '
    select(length > 0 and (startswith("#") | not))
    | capture("^(?<k>[A-Z][A-Z0-9_]*)=(?<v>.*)$")
    | (.k | ascii_downcase | gsub("_"; "-")) as $label
    | { id: "\($app)-\($label)", section: { id: $app, label: $app },
        label: $label, type: "CONCEALED", value: .v }' \
    < <(remote "cat /var/lib/secrets/$app/env") >>"$tmp/apps.jsonl"
done

jq -n \
  --arg title "$item" \
  --rawfile repo <(remote 'cat /var/lib/secrets/restic/repository') \
  --rawfile password <(remote 'cat /var/lib/secrets/restic/password') \
  --rawfile keyid <(envvar AWS_ACCESS_KEY_ID) \
  --rawfile secret <(envvar AWS_SECRET_ACCESS_KEY) \
  --rawfile hostkey <(remote 'base64 -w0 /etc/ssh/ssh_host_ed25519_key') \
  --slurpfile apps "$tmp/apps.jsonl" \
  '
  def field($label; $value): {
    id: $label, label: $label, type: "CONCEALED",
    value: ($value | rtrimstr("\n"))
  };
  {
    title: $title,
    category: "SECURE_NOTE",
    notesPlain: "charon VPS secrets, read by nix/hosts/charon/scripts/provision.sh and written by save-secrets.sh. ssh-host-ed25519-key is base64. Each section is /var/lib/secrets/<section>/env.",
    sections: ($apps | map(.section) | unique),
    fields: ([
      field("restic-repository"; $repo),
      field("restic-password"; $password),
      field("r2-access-key-id"; $keyid),
      field("r2-secret-access-key"; $secret),
      field("ssh-host-ed25519-key"; $hostkey)
    ] + $apps)
  }' >"$tmp/item.json"

if jq -e '.fields | any(.value == "")' "$tmp/item.json" >/dev/null; then
  echo "a secret read from $host was empty; nothing was saved" >&2
  exit 1
fi

if op item get "$item" --vault "$vault" >/dev/null 2>&1; then
  op item delete "$item" --vault "$vault" --archive
  echo "archived the previous '$item' item in $vault"
fi
op item create --vault "$vault" --template "$tmp/item.json" --format json |
  jq -r '"saved \(.title) to \(.vault.name); app fields: \([.fields[] | select(.section.label? // "" | length > 0) | "\(.section.label)/\(.label)"] | if length > 0 then join(", ") else "none" end)"'
