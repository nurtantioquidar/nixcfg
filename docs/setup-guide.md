# Nix Setup Guide

This repository manages three flake outputs:

- `darwinConfigurations.styx` for the macOS host, with `darwinConfigurations.MAC-F0Q3XN9HR9` as the IT hostname alias.
- `nixosConfigurations.wsl` for the NixOS-WSL host.
- `homeConfigurations.hades` for standalone macOS Home Manager activation.

Darwin is the primary system path in this guide. WSL uses the same Home Manager profile where practical. On macOS, day-to-day user-level changes should prefer standalone Home Manager when they do not need root.

## Prerequisites

- Nix with flakes enabled.
- `nix-darwin` available on macOS.
- Home Manager through this flake.
- 1Password for Git SSH signing on macOS, if signed commits are required.

If the current shell does not have flakes enabled yet, bootstrap or verify commands can be run with explicit feature flags:

```bash
nix --extra-experimental-features nix-command --extra-experimental-features flakes flake check --no-build
```

## Rebuild Commands

From this repository:

```bash
sudo darwin-rebuild switch --flake /Users/hades/.config/nix#styx --impure
sudo nixos-rebuild switch --flake ~/.config/nix#wsl
```

Select the Darwin output explicitly with `#styx` for the friendly name, or `#MAC-F0Q3XN9HR9` when matching the IT-managed hostname.

With flakes, local changes must be visible to Git before a rebuild can read them. Stage or commit changed files first when a rebuild says a path is missing from the source tree.

For user-level macOS changes, use the standalone Home Manager profile without sudo.

Validate the Home Manager graph first:

```bash
nix --extra-experimental-features nix-command --extra-experimental-features flakes build /Users/hades/.config/nix#homeConfigurations.hades.activationPackage --impure
```

Activate it only when the change should be applied to the user environment:

```bash
home-manager switch --extra-experimental-features nix-command --extra-experimental-features flakes --flake /Users/hades/.config/nix#hades --impure
```

Use this path for user packages, shells, Git, prompt, dotfiles, and other user-scoped settings. Keep `sudo darwin-rebuild` for system state such as users, login shell registration, hostname, Nix daemon/global settings, Homebrew bootstrap, pinned Homebrew taps, and privileged Homebrew casks.

## Documentation Conventions

Markdown documentation filenames should use lower kebab case, such as `docs/setup-guide.md` and `docs/secrets-setup.md`.

`AGENTS.md` is the only uppercase filename exception.

## Shell And Prompt

The system login shell is Fish on both hosts, and Home Manager imports both `nix/home/fish.nix` and `nix/home/zsh.nix`. The active Starship prompt configuration lives in `nix/home/home.nix` and enables integration for both shells:

```nix
programs.starship = {
  enable = true;
  enableFishIntegration = true;
  enableZshIntegration = true;
  settings = {
    add_newline = true;
    command_timeout = 500;
    scan_timeout = 10;
    format = "$username$hostname$directory$git_branch$git_status$character";

    git_status.disabled = true;
  };
};
```

`git_status.disabled = true` means the prompt currently shows the Git branch but not dirty, staged, ahead, or behind status. Remove or set that option to `false` if prompt Git status should be restored.

Fish is the shell that should receive day-to-day PATH and SDKMAN behavior. `nix/home/fish.nix` points SDKMAN at `$HOME/.sdkman`, matching the Home Manager activation that installs SDKMAN there.

## macOS User Preferences

Standalone Home Manager manages user-scoped macOS preferences and assets where possible:

- Dock orientation, autohide, tile size, `show-recents`, and `static-only`.
- Fira Code and JetBrains Mono Nerd Fonts under `~/Library/Fonts/HomeManager`.
- App links under `~/Applications/home-manager-apps`.

Dock persistent apps remain in nix-darwin for now because nix-darwin exposes a richer `system.defaults.dock.persistent-apps` option than Home Manager's typed Darwin defaults module.

Spotlight must be enabled for user apps to appear in Spotlight search. If `mdutil -s "$HOME"` reports that the Spotlight server is disabled, app registration and `mdimport` will not make those apps searchable until Spotlight is enabled by policy or admin action.

Normal macOS GUI apps should stay out of Home Manager unless a specific app has been proven reliable from Home Manager. Home Manager links app bundles into `~/Applications/home-manager-apps` as symlinks to `/nix/store`; several GUI apps failed macOS code-signing/Gatekeeper checks from that location. Keep Home Manager focused on CLI/dev tools and user-scoped configuration.

Ordinary Homebrew casks are declared in `nix/home/homebrew.nix`. The current working-tree user cask list includes ordinary app bundles plus explicit user-owned entries such as `claude`, `soundsource`, and `orbstack`; do not reclassify or remove those entries during audit-only work without an explicit approval step.

Validate cask-list edits with the Home Manager activation package build before applying them:

```bash
nix --extra-experimental-features nix-command --extra-experimental-features flakes build /Users/hades/.config/nix#homeConfigurations.hades.activationPackage --impure
```

Activate only when the change should be applied and potential Homebrew cask state changes have been reviewed:

```bash
home-manager switch --extra-experimental-features nix-command --extra-experimental-features flakes --flake /Users/hades/.config/nix#hades --impure
```

The module writes `~/.config/homebrew/Brewfile` and runs `brew bundle install --no-upgrade` as the user. Home Manager exports `HOMEBREW_CASK_OPTS=--appdir=/Users/hades/Applications` on macOS, so ordinary app-bundle casks install real app bundles under the user-owned `~/Applications` directory without requiring `sudo darwin-rebuild`. Casks that run package installers or install VPNs, system extensions, audio drivers, virtualization helpers, or other privileged components may still need admin privileges; keep those in `nix/hosts/mbp/homebrew.nix`.

Tinycast is installed from its pinned third-party cask. The activation trusts only `abue-ammar/tinycast/tinycast`, rather than the entire tap. `nix/home/tinycast.nix` manages its launcher search scopes and places `~/Applications/Claude.app` before `/Applications`, ensuring Tinycast keeps the user-owned, upgradeable Claude Desktop bundle when both copies share the same bundle identifier.

The user-level Brewfile does not run `brew bundle cleanup`. Cleanup is intentionally manual because Homebrew cleanup sees all installed casks, including privileged casks owned by the Darwin profile. Removing a cask from the user-managed list can still uninstall a previously managed cask during Home Manager activation unless that cask remains explicitly exempted or is moved through an approved user/admin flow. For drift audits, compare declared lists and `brew list --cask` output as a report-only check; do not uninstall or cleanup as part of the audit.

## Codex CLI

Codex CLI is user-managed through `nix/home/codex.nix` instead of the nixpkgs `codex` package. Home Manager installs the official standalone CLI into `~/.local/bin/codex` when it is missing and provides this updater:

```bash
codex-upgrade
```

`codex-upgrade` reruns OpenAI's standalone installer with `CODEX_NON_INTERACTIVE=1`, matching the official macOS/Linux install and upgrade path documented at <https://developers.openai.com/codex/cli>. This keeps Codex CLI upgrades out of the sudo or Homebrew path.

## Rust Development

The shared Home Manager profile installs the latest stable Rust toolchain from the pinned `rust-overlay` flake input. It includes `rustc`, Cargo, Clippy, rustfmt, `rust-analyzer`, the standard-library source, and API documentation. `RUST_SRC_PATH` is configured for tools that need to inspect the standard library.

Because the toolchain is in `home.packages`, it is available to interactive shells and coding agents after activating Home Manager:

```bash
home-manager switch --extra-experimental-features nix-command --extra-experimental-features flakes --flake /Users/hades/.config/nix#hades --impure
```

The repository's default `nix develop` shell uses the same toolchain definition. Update the pinned Rust release with the normal flake input update workflow rather than `rustup`.

## Herdr

Herdr is installed for macOS and WSL through the pinned upstream `herdr` flake input and the shared `nix/home/herdr.nix` module. Upgrade the pin and rebuild the standalone Home Manager profile with:

```bash
nix flake update herdr
home-manager switch --extra-experimental-features nix-command --extra-experimental-features flakes --flake /Users/hades/.config/nix#hades --impure
```

Start or reattach to the default session with `herdr`. Because Nix owns the binary, use the flake update workflow rather than `herdr update`.

## VS Code

VS Code Settings Sync is the source of truth for settings, extensions, keybindings, snippets, and profiles.

VS Code is kept as a user-scoped macOS app at `/Users/hades/Applications/Visual Studio Code.app`. Home Manager installs a user-level `code` wrapper that executes `/Users/hades/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code` so the CLI is available without admin privileges and without shell alias quoting issues. This home-directory app path is intentional because previous VS Code ownership and app-bundle handling caused issues when moving between Homebrew, Home Manager app links, and system locations.

Do not import `nix/home/vscode.nix` as-is unless declarative VS Code settings and extensions are intentionally desired; Settings Sync remains responsible for that user data.

## Git Configuration

Git is managed by `nix/home/git.nix`. It installs `gh`, enables Git LFS, configures global ignores, and uses `programs.git.settings` for Git options. 1Password signing is enabled only on Darwin when `sshSigningKey` is non-empty:

```nix
programs.git = {
  enable = true;
  lfs.enable = true;

  ignores = [
    ".DS_Store"
    "*.swp"
    "*~"
    ".idea/"
    ".vscode/"
    "*.iml"
    ".claude/"
  ];

  settings = {
    user = {
      name = secrets.userName;
      email = secrets.userEmail;
    };

    init.defaultBranch = "main";
    pull.rebase = true;
    push.autoSetupRemote = true;
  };
};
```

The fallback values in `git.nix` are placeholders. Configure the external secrets file before expecting Git identity to be correct. On macOS, Git commit signing is configured only when the external secrets file contains `sshSigningKey`.

## Secrets

`nix/home/git.nix` reads secrets from an absolute path outside the flake:

```text
macOS: /Users/hades/.config/nix-secrets/git-secrets.nix
WSL:   /home/hades/.config/nix-secrets/git-secrets.nix
```

See `docs/secrets-setup.md` for the focused setup flow.

Create it from the template:

```bash
mkdir -p ~/.config/nix-secrets
cp ~/.config/nix/nix/home/secrets.nix.template ~/.config/nix-secrets/git-secrets.nix
nvim ~/.config/nix-secrets/git-secrets.nix
```

Expected shape:

```nix
{
  userName = "Your Name";
  userEmail = "your.email@example.com";
  sshSigningKey = "ssh-ed25519 AAAA...";
}
```

Keep this file outside the flake. If the username or home directory changes, update `secretsPath` in `nix/home/git.nix`.

To check that Nix can read the file:

```bash
nix-instantiate --eval -E 'import /Users/hades/.config/nix-secrets/git-secrets.nix'
# WSL:
nix-instantiate --eval -E 'import /home/hades/.config/nix-secrets/git-secrets.nix'
```

## 1Password CLI

The macOS Home Manager profile installs the 1Password CLI as `op`. The Nix package also provides Bash, Fish, and Zsh completions.

After activating Home Manager, enable biometric authentication through the existing 1Password desktop app:

1. Open and unlock 1Password.
2. Go to **Settings > Developer**.
3. Enable **Integrate with 1Password CLI**.
4. Enable Touch ID in 1Password if it is not already enabled.

Verify the installation and authorize access from the desktop app:

```bash
op --version
op vault list
```

If multiple accounts are configured in the desktop app, run `op signin` to select one.

## 1Password Git Signing

The macOS Git signing setup is enabled only when `sshSigningKey` is configured:

- `gpg.format = "ssh"`
- `gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"`
- `gpg.ssh.allowedSignersFile = "~/.config/git/allowed_signers"`
- `user.signingkey = secrets.sshSigningKey`
- `commit.gpgsign = true`

Enable the 1Password SSH agent in the 1Password macOS app, create or choose an SSH key, copy its public key, and put that public key in `sshSigningKey` in `/Users/hades/.config/nix-secrets/git-secrets.nix`. Home Manager writes `~/.config/git/allowed_signers` from `userEmail` and `sshSigningKey`, which lets local Git verify SSH signatures instead of reporting `No signature`.

For GitHub verification, add the same public key at `https://github.com/settings/keys` as a signing key, not only as an authentication key.

After rebuilding, verify the effective Git configuration:

```bash
git config --get gpg.format
git config --get gpg.ssh.program
git config --get gpg.ssh.allowedSignersFile
git config --get user.signingkey
git config --get commit.gpgsign
nix/hosts/mbp/scripts/verify-1password-signing.sh
```

The verification script creates a temporary repository with `mktemp`, attempts a signed test commit there, and cleans it up automatically, so it does not require modifying repository files.

## SSH Agent Configuration

`nix/home/ssh.nix` manages the user SSH client config through Home Manager. It preserves the OrbStack and Colima include files and configures the 1Password SSH agent for all hosts:

```sshconfig
Include ~/.orbstack/ssh/config /Users/hades/.colima/ssh_config

Host *
    IdentityAgent ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
```

The pre-Home Manager SSH config was backed up during migration:

```sshconfig
~/.ssh/config.backup
```

## WSL Notes

The WSL host is `nixosConfigurations.wsl`. It imports `nix/hosts/wsl/configuration.nix` and `nix/hosts/wsl/packages.nix`.

This repo keeps WSL networking simple by leaving NetworkManager disabled and letting WSL manage `/etc/resolv.conf`. If NetworkManager is enabled later, revisit resolver management at the same time to avoid ownership conflicts.

Rebuild WSL with:

```bash
sudo nixos-rebuild switch --flake ~/.config/nix#wsl
```

## Troubleshooting

### Homebrew Cask API Fails During Rebuild

`nix/hosts/mbp/homebrew.nix` lets Homebrew update during activation and runs `brew bundle` for privileged casks with `HOMEBREW_NO_INSTALL_FROM_API=1`. This avoids failures in Homebrew's cask API loader, such as:

```text
Error: undefined method 'to_sym' for nil
Error: Cask 'codex' definition is invalid: 'generate_completions_from_executable' does not support shell(s): bash, zsh, fish
```

Disabling the API means Homebrew must resolve casks from a local tap checkout instead of the JSON API. If `homebrew/homebrew-cask` is not available locally, newer casks can fail with a misleading formula error:

```text
Error: No available formula with the name "chatgpt".
```

To cover both cases, this repo pins `github:homebrew/homebrew-cask` as the `homebrew-cask` flake input and exposes it through `nix-homebrew.taps."homebrew/homebrew-cask"`. Keep `homebrew/cask` in `homebrew.taps` too, so nix-darwin's generated Brewfile can resolve casks without using the API.

Third-party taps that provide casks follow the same split. For example, cmux uses the Brewfile tap alias `manaflow-ai/cmux`, while `nix-homebrew.taps."manaflow-ai/homebrew-cmux"` points at the pinned `git+https://github.com/manaflow-ai/homebrew-cmux.git` flake input.

AeroSpace is fully user-managed: `nix/home/homebrew.nix` installs the official `nikitabobko/tap/aerospace` cask and `nix/home/aerospace.nix` manages `~/.config/aerospace/aerospace.toml`, so setup and upgrades do not require `sudo darwin-rebuild` or admin access. The managed bindings use `Alt+h/j/k/l` for focus, `Alt+Shift+h/j/k/l` for moves, and `Alt+1` through `Alt+9` for workspaces; Option+Arrow remains available for shell word navigation.

When adding a new cask that exists in Homebrew's API but fails during activation, check both paths:

```bash
brew info --cask <name>
HOMEBREW_NO_INSTALL_FROM_API=1 brew info --cask <name>
```

The first command tests API-backed resolution. The second command tests the same no-API path used by `darwin-rebuild`.

If a newer cask uses DSL that the pinned Homebrew source cannot parse, update `nix-homebrew` and `homebrew-cask` together so the Homebrew loader and cask tap stay compatible:

```bash
nix --extra-experimental-features nix-command --extra-experimental-features flakes flake update nix-homebrew homebrew-cask
sudo darwin-rebuild switch --flake /Users/hades/.config/nix#styx --impure
```

### A Cask Vendor Download Fails

If one privileged cask download returns a vendor-side HTTP error, `brew bundle` fails the whole activation. Keep that app out of `homebrew.casks` until the vendor URL is healthy again, then install it manually or re-enable it in `nix/hosts/mbp/homebrew.nix`.

CLI tools are usually better managed through Nix when possible. For example, Google Cloud SDK is installed as `google-cloud-sdk` through Home Manager instead of the Homebrew `gcloud-cli` cask, avoiding Caskroom upgrade state failures during activation.

### Homebrew Cleanup Refuses To Uninstall Dependencies

This config uses `homebrew.onActivation.cleanup = "none"` so ordinary user-installed Homebrew apps are not pruned during activation. If cleanup is temporarily changed to `uninstall` or `zap`, remember that unmanaged casks installed outside `nix/hosts/mbp/homebrew.nix` may be removed during the next `sudo darwin-rebuild`.

### Homebrew Cask Removal Hits Immutable Files

If `brew bundle cleanup` or `brew uninstall --cask` cannot remove an old app because files are marked immutable, clear the flag during an admin window and retry the cask removal:

```bash
sudo chflags -R nouchg /Applications/Visual\ Studio\ Code.app /opt/homebrew/Caskroom/visual-studio-code
brew uninstall --cask --force visual-studio-code
```

This was needed when moving VS Code from Homebrew cask ownership to the Home Manager `pkgs.vscode` app link under `~/Applications/home-manager-apps`. The same pattern was also needed when removing the old Claude Desktop cask after Electron framework symlink/chflags backup errors.

### NPM Deprecation Warnings During Rebuild

`nix/home/node-packages.nix` manages selected global npm packages under `~/.local`. It also writes `~/.npmrc` with `prefix=/Users/hades/.local` and `cache=/Users/hades/.cache/npm` so manual `npm install --global ...` commands do not try to write into the immutable Nix store. The activation checks whether each package is already installed before running `npm install --global`, so transitive npm warnings should appear only when a package is missing and installation actually runs. Existing packages are intentionally not upgraded during activation because that would make every Home Manager switch depend on npm and network availability. Upgrade all packages declared by the module explicitly with:

```bash
node-packages-upgrade
```

If `npm install -g ...` fails with `EACCES` while trying to create a directory under `/nix/store/...nodejs...`, confirm the npm prefix:

```bash
npm config get prefix
```

It should print `/Users/hades/.local` after Home Manager activation.

### Starship Looks Unchanged

Open a new terminal, confirm the active shell is loading Home Manager output, and check that Starship is installed:

```bash
which starship
echo $SHELL
```

### Zellij Leaks `?997;2n` In This Repo

`/Users/hades/.config/nix/.envrc` uses `use flake`, so direnv can enter a Nix shell that sets `TMPDIR` to a transient `nix-shell.*` directory. Zellij uses `TMPDIR` for runtime socket and log state, which can break Ghostty/Zellij startup and leave terminal DSR responses like `?997;2n` in the shell prompt.

`nix/home/zellij.nix` installs a Home Manager-managed Zellij wrapper that normalizes `TMPDIR` back to the parent macOS temp directory before launching Zellij, sets `ZELLIJ_SOCKET_DIR` to a short per-user `/tmp` path so long session names do not exceed macOS socket path limits, downgrades Ghostty's outer `TERM` to `xterm-256color`, and drains a late DSR response on exit. `nix/home/ghostty.nix` writes `~/.config/ghostty/config` with `macos-option-as-alt = left` so the left Option key works as terminal Alt for Zellij bindings while the right Option key remains available for macOS character input.

The managed Zellij config clears default bindings and restates the defaults that should remain, which intentionally removes Zellij's `Alt+Left`/`Alt+Right` bindings so Ghostty/shell word navigation keeps working. `nix/home/zsh.nix` binds common `Option+Left` and `Option+Right` escape sequences, including Ghostty/Zellij modified arrows, to zsh word movement. If pressing `Option+Left` inserts `D` or `Option+Right` inserts `C`, zsh is receiving the final byte of an unbound arrow sequence and those `bindkey` entries should be checked after Home Manager activation. Use `Alt+Shift+f` for floating panes, `Alt+Shift+n` for a new tab, and `Ctrl+y` for zellij-forgot. The zellij-autolock plugin is defined but intentionally not loaded because upstream issue fresh2dev/zellij-autolock#20 reports that it can immediately undo manual `Ctrl+g` lock changes. For Zellij prompts that show `<Del>`, use `Fn+Delete` on Mac keyboards; the key labeled Delete is normally Backspace, and Ghostty cannot bind `fn` directly. Keep future Zellij wrapper fixes in `nix/home/zellij.nix`, Ghostty config fixes in `nix/home/ghostty.nix`, and shell word-navigation fixes in `nix/home/zsh.nix`.

### Secrets Are Placeholders

Check the external file and the path hard-coded in `nix/home/git.nix`:

```bash
ls -la ~/.config/nix-secrets/git-secrets.nix
nix-instantiate --eval -E 'import /Users/hades/.config/nix-secrets/git-secrets.nix'
```

Then stage or commit Nix file changes and rebuild the relevant host.

### Commits Are Not Signed

Check the generated Git config:

```bash
git config --get gpg.format
git config --get gpg.ssh.program
git config --get gpg.ssh.allowedSignersFile
git config --get user.signingkey
git config --get commit.gpgsign
```

If these values are missing on macOS, rebuild the flake and confirm the secrets file contains `sshSigningKey`. On WSL, the 1Password signing values are intentionally omitted.

If commits are signed but `git log --show-signature` reports `No signature`, confirm `gpg.ssh.allowedSignersFile` points to an existing file generated by Home Manager, then rebuild the flake.

### Flake Commands Fail Before Rebuild

If `nix flake ...` fails with `experimental Nix feature 'nix-command' is disabled`, run the command with explicit feature flags:

```bash
nix --extra-experimental-features nix-command --extra-experimental-features flakes flake check --no-build
```

On the Darwin host, this flake currently sets `nix.enable = false`, so nix-darwin is not the component managing `/etc/nix/nix.conf`. Enable `nix-command` and `flakes` in the external Nix installation, or keep passing the explicit feature flags.

### GitHub Shows Unverified

Confirm the public key in `sshSigningKey` is added to GitHub as a signing key and that the commit email matches an email on the GitHub account.
