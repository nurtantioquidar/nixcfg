# Restore styx after a macOS reinstall

The personal MBP uses `hades`, `/Users/hades`, UID 501, and the `#styx`
Darwin output. The company MBA uses the same home path but UID 503. Restore as
the target user so files belong to UID 501; do not preserve source numeric ownership.

## Prepare user state on the source

Run from this repository, using a new directory outside the flake:

```sh
python3 nix/hosts/mbp/scripts/prepare-migration.py \
  --output /private/tmp/styx-migration
```

The helper creates a private `home/` tree, a manifest, and a `READY` marker only
after successful completion. It copies the current repository including Git
history, external Nix secrets, unmanaged user config, Claude and Codex transcripts,
skills, hooks, plugins, and file-based credentials. It snapshots SQLite databases
through the online backup API and checks their integrity, retaining committed
WAL entries without copying active WAL files. Python SQLite may need permission
to open the source databases' shared-memory files.

Nix-managed store links, agent sockets, installed CLI binaries, process state,
logs, and caches are omitted. Home Manager recreates its managed files and installs
missing Claude/Codex binaries. Source SSH `authorized_keys` and 1Password device
state are omitted: configure incoming access and sign into 1Password on the MBP.
Project working trees and their local `.env` files need a separate transfer to the
same absolute paths when resuming conversations that reference them.

The helper does not export macOS Keychain items. For a live assisted transfer,
export only the requested Claude/GitHub items to private files without displaying
values; avoid copying the whole company Keychain or device trust credentials.
[Claude Code](https://code.claude.com/docs/en/authentication) normally uses Keychain
on macOS. Preserve the private `.claude/.credentials.json` fallback when present,
but verify the installed CLI recognizes it. The styx migration required importing
the current credential into Keychain; a copied fallback alone was not recognized.
For an assisted export named `keychain-export/claude-current.secret`, run locally:

```sh
python3 ~/.config/nix/nix/hosts/mbp/scripts/import-claude-keychain.py \
  ~/styx-migration/keychain-export/claude-current.secret
```

The helper stores only the named Claude credential and restricts a new item's
reader to macOS's `security` tool. It unlocks the default Keychain at a local
password prompt if needed; it does not receive that password. Before replacing
a different existing credential, it saves a private backup beside the input file.
It does not print tokens or pass them as process arguments. SSH can receive OSStatus `-25308`
(interaction not allowed), so run at the console. A duplicate-item result does
not establish a working login: a locked Keychain can hide an existing item.
Use a fresh export when the source has refreshed its token since preparation.
Verify Claude from the MBP's local Terminal. A later SSH session can still see a
locked default Keychain and report no login even after the console reports
`Claude logged in: True`; check that session's Keychain lock state before
attempting another import.

The observed store is the local `~/Library/Keychains/login.keychain-db`, not
iCloud Keychain. SSH and Git signing use 1Password; the shells do not load keys
from Apple Keychain. A supported alternative for Claude is a subscription token
from `claude setup-token`, stored in 1Password and injected at launch with
`op run` as `CLAUDE_CODE_OAUTH_TOKEN`. This token route cannot establish Remote
Control sessions or fetch claude.ai connectors, so choose it only after settling
the owner's feature preference. Codex currently documents file, OS keyring,
automatic, and ephemeral storage, without a native 1Password ChatGPT credential
store. A vault backup is distinct from its runtime authentication cache.
[Codex](https://learn.chatgpt.com/docs/auth) supports transferring its file-based
`auth.json`; account logins may still need renewal. GitHub token imports should
use `gh auth login --with-token` through stdin after installing `gh`.

Online database backups allow preparation during an active session, but the
snapshot is not atomic across all files or databases. Idle other agents first
when possible and refresh the snapshot for conversations changed afterward.

## Transfer and restore

Enable Remote Login for `hades` on the MBP. Verify its SSH host fingerprint from
the MBP console before sending credentials. Transfer through verified SSH or
AirDrop and keep the staging folder private. `rsync -a --partial` can resume an
interrupted SSH copy. Verify the complete payload before restoring; the `READY`
marker alone cannot prove the transport finished.

On the MBP, inspect existing destination files and back them up before overwriting
them. Restore the payload as `hades`, without sudo and without numeric ownership
preservation. Keep existing `.ssh/authorized_keys` so bootstrap access survives.
Preserve `/Users/hades` and project paths so session references keep matching.

## Bootstrap Nix and Darwin

Check the source's `nix --version`, `/nix/receipt.json`, and installer comments in
`/etc/nix/nix.conf` before choosing an installer. In October 2026 the MBA uses
upstream Nix 2.35.2 and the NixOS community installer. A matching fresh installation
uses the command from the [NixOS installer](https://github.com/NixOS/nix-installer):

```sh
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
```

Run the installer locally on the MBP so it can request the admin password. Open a
new terminal afterward. The laptop modules use `nix.enable = false`, retaining
the external Nix installation. Homebrew bootstrap and pinned taps are owned by
Darwin; do not install a separate competing Homebrew tree.

Validate before activation:

```sh
nix --extra-experimental-features nix-command --extra-experimental-features flakes \
  flake check path:/Users/hades/.config/nix --no-build --no-update-lock-file
nix --extra-experimental-features nix-command --extra-experimental-features flakes \
  build path:/Users/hades/.config/nix#darwinConfigurations.styx.system \
  --impure --no-link --no-update-lock-file
```

Using a `path:` URL includes restored helper/docs files that are not yet tracked.
For first activation, follow [nix-darwin's bootstrap instructions](https://github.com/nix-darwin/nix-darwin)
with the explicit personal host:

```sh
sudo nix --extra-experimental-features nix-command --extra-experimental-features flakes \
  run nix-darwin/master#darwin-rebuild -- switch \
  --flake path:/Users/hades/.config/nix#styx --impure
```

Future activations use `sudo darwin-rebuild switch --flake /Users/hades/.config/nix#styx --impure`.
The first switch also activates the shared Home Manager profile. Do not activate
the company MBA output on styx.

For an assisted migration, the source can export the closure of its validated
styx build with `nix-store --export`, compress it, and transfer it over verified
SSH. A bundle with `styx-system.nar.gz`, its `styx-system.sha256` checksum,
`system-path.txt`, and the `RESTORED` marker can then use:

```sh
bash ~/.config/nix/nix/hosts/mbp/scripts/activate-migration.sh ~/styx-migration
```

This runs as `hades` in the MBP's local Terminal, requests sudo, verifies the
archive, imports the existing packages, and switches the explicit styx profile.
Only this root import bypasses signature checks for locally built store paths;
no persistent Nix trust settings are changed. Running locally also permits
macOS App Management prompts. If Darwin reports unexpected `/etc` files, inspect
and preserve the reported files with `.before-nix-darwin` backups before retrying.

## Recover a stalled first Homebrew core clone

The no-API activation path needs a local `homebrew/core` checkout. Its full Git
history is large, and the initial clone can hang on a dead HTTPS transfer. Check
the Git processes and the size/mtime of `.git/objects/pack/tmp_pack_*`; a quiet
terminal alone does not establish a stall.

When stalled, stop the activation's Git transport and user-owned Brew process
before installing a replacement. If the other Mac already has a complete,
clean, non-shallow `homebrew/core` checkout with the official GitHub remote,
copy it into a private target staging directory over verified SSH. Verify the
copied checkout's commit, working-tree status, Git object connectivity, and
`git rev-parse --is-shallow-repository` before moving it into the missing ordinary
`/opt/homebrew/Library/Taps/homebrew/homebrew-core` directory as `hades`.

This applies only to the user-owned core directory, never the pinned third-party
or cask tap symlinks. Preserve any remaining failed checkout as a backup. A
shallow clone is unsuitable: Homebrew refuses normal core updates until it is
unshallowed. Keep `HOMEBREW_NO_INSTALL_FROM_API=1` and retry the local styx
activation after `brew tap-info homebrew/core` succeeds. Rosetta warnings concern
the separate Intel prefix and do not explain a stalled Git clone.

## ExpressVPN excluded from styx

The pinned ExpressVPN 14.2.1 cask invokes an app installer with sudo. On a fresh
styx installation it failed with `Failed to send install request to install
helper`, leaving an app bundle but no ExpressVPN group or registered daemon.
This stops Darwin's Brew bundle even when later casks install successfully.

A checksum- and signature-verified copy of the pinned installer also failed
through its normal GUI helper prompt. At the owner's request, ExpressVPN was
removed from the personal MBP's Darwin cask list. The company MBA's separate
baseline leaves its company-managed ExpressVPN outside Homebrew. Do not
reintroduce ExpressVPN into styx's bootstrap. A failed install can leave partial
root-owned files; removing the declaration with Homebrew cleanup set to `none`
does not uninstall those.

## Fresh Homebrew user-install directories

nix-homebrew can create the ordinary `Library/Taps` parent as root on a fresh
prefix. Home Manager then cannot create the new `crmne` namespace for Spotifast
and ZapFast. Styx's Homebrew module now creates only that namespace, owned by
`hades:admin`, after nix-homebrew setup and before user activation. Do not
recursively change ownership of the prefix or pinned taps.

Home Manager creates `share/pwsh/completions` before installing casks. Zed's
generated-completion sandbox permits the leaf directory but cannot create
missing parents. The warning does not by itself mean the Zed app failed.

## Verify and finish

Sign into 1Password and enable its SSH agent and CLI integration. The source MBA
has no private SSH key files; access to those keys comes from the 1Password vault.
Verify Git signing and SSH authentication using the existing key. Check `codex
login status`, Claude authentication, `gh auth status`, and the resumed session
pickers after installation. Source browser cookies, device permissions, and
company device enrollment are outside this transfer.

Confirm app installs and terminal config, and transfer any needed working trees
to their original locations. Remove temporary SSH bootstrap keys once permanent
access works. Keep the source untouched until restore verification succeeds;
remove private staging exports when they are no longer needed.

Verify Styx Chrome at `~/Applications/Google Chrome.app`, owned by `hades`, with
the same user path in the MBP Dock configuration. Its personal-only user Homebrew
activation lives in `nix/hosts/mbp/homebrew.nix`. An existing system installation
needs a one-time user-level reinstall with `--appdir="$HOME/Applications"`; see
[Chrome installation and startup troubleshooting](setup-guide.md). If it crashes
immediately, check ownership of `~/Library/Application Support/Google` before
resetting browser data; an empty root-owned directory blocked Chrome on styx.
