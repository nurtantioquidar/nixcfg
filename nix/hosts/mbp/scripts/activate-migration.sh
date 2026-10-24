#!/bin/bash
# Run in the MBP's local Terminal after receiving an assisted migration bundle.
set -euo pipefail

if [[ $(uname -s) != Darwin || $(uname -m) != arm64 || $(id -un) != hades || $(id -u) != 501 ]]; then
  echo "Run this as hades (UID 501) on the personal Apple Silicon MBP." >&2
  exit 1
fi
if [[ $# != 1 ]]; then
  echo "Usage: bash $0 /Users/hades/<migration-folder>" >&2
  exit 1
fi

migration_dir=$(cd "$1" && pwd -P)
cd "$migration_dir"
test -f RESTORED
test -f styx-system.nar.gz
test -f styx-system.sha256
test -f system-path.txt
/usr/bin/shasum -a 256 -c styx-system.sha256
system_path=$(cat system-path.txt)
case "$system_path" in
  /nix/store/*-darwin-system-*) ;;
  *) echo "Invalid system path in migration bundle." >&2; exit 1 ;;
esac

# Authenticate at the local terminal before piping package data through sudo.
sudo -v
if /nix/var/nix/profiles/default/bin/nix --extra-experimental-features nix-command \
  path-info --recursive "$system_path" >/dev/null 2>&1; then
  echo "Validated system closure is already imported; continuing activation."
else
  /usr/bin/gzip -dc styx-system.nar.gz | \
    sudo -n /nix/var/nix/profiles/default/bin/nix-store --import \
      --option require-sigs false > nix-import.log
fi

# The imported closure was built and checked on the source Mac. Signature
# enforcement was disabled only for that root import, never in nix.conf.
sudo "$system_path/sw/bin/darwin-rebuild" switch \
  --flake path:/Users/hades/.config/nix#styx --impure
touch ACTIVATED
echo "Styx activated. Open a new terminal before checking tools and logins."
