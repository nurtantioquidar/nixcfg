# Privilege Audit: nix-darwin and Home Manager

This document classifies the macOS Nix configuration by privilege level. The goal is to identify what can be managed as the normal `hades` user with Home Manager, and what still requires temporary admin access with `sudo darwin-rebuild`.

The current macOS host is `darwinConfigurations.styx`. The repo also exposes `homeConfigurations.hades` for standalone user-level Home Manager activation.

## Mental Model

Use this rule of thumb:

- Home Manager manages files, packages, shell config, app links, launch agents, and environment under the user account.
- nix-darwin manages system state: users, login shells, `/etc`, Nix daemon/global settings, system defaults, `/Library`, LaunchDaemons, and Homebrew bootstrap state.
- VPNs, audio drivers, security tools, and virtualization apps often install privileged helpers or system extensions even when they look like normal `.app` bundles.

## Already In Home Manager

These are already user-level in `nix/home` and should not require sudo once Home Manager can be run standalone.

### Main Home Profile

Defined in `nix/home/home.nix`:

- `home.stateVersion`
- WezTerm dotfile at `~/.config/wezterm/wezterm.lua`
- User packages:
  - `htop`
  - `curl`
  - `coreutils`
  - `jq`
  - `ripgrep`
  - `ngrok`
  - `unzip`
  - `zip`
  - `go`
  - `gopls`
  - `delve`
  - `mockgen`
  - `google-cloud-sdk`
- User session variables:
  - `PATH`
  - `EDITOR`
  - `VISUAL`
  - `GIT_EDITOR`
- SDKMAN activation under `~/.sdkman`
- `dircolors`
- `direnv`
- Starship prompt for Fish and Zsh

### Git

Defined in `nix/home/git.nix`:

- `gh`
- Git
- Git LFS
- Global Git ignores
- Git identity from the external secrets file
- Git defaults such as rebase, pruning, diff behavior, rerere, and maintenance
- macOS-only 1Password SSH signing when `sshSigningKey` is present
- `~/.config/git/allowed_signers`

This is user-level because it writes to the user's Git config and home directory.

### Shells

Defined in:

- `nix/home/fish.nix`
- `nix/home/zsh.nix`
- `nix/home/bash.nix`

Home Manager owns:

- Fish interactive config
- Zsh interactive config
- Bash enablement
- Shell aliases
- PATH additions
- SDKMAN shell integration
- Oh My Zsh
- Zsh syntax highlighting
- Zsh autosuggestions
- `GPG_TTY`
- Apple keychain SSH loading commands

The interactive shell config is user-level. The system login shell assignment is not; that remains under `users.users.hades.shell` in nix-darwin.

### Language And Tool Activation

Defined in:

- `nix/home/node-packages.nix`
- `nix/home/claude-code.nix`

Home Manager owns:

- Node.js 24
- selected npm globals under `~/.local`
- Claude Code install under `~/.local/bin`

### Enabled Tool Modules

These modules are imported from `nix/home/home.nix` and activate at user level:

- `nix/home/ssh.nix`
- `nix/home/nvim.nix`
- `nix/home/tmux.nix`

`nix/home/ssh.nix` preserves the existing OrbStack and Colima include files while managing the 1Password SSH agent config. The pre-Home Manager SSH config was backed up to `~/.ssh/config.backup` during migration.

### Inactive Home Manager Modules

These modules exist but are not currently imported from `nix/home/home.nix`:

- `nix/home/vscode.nix`

`nix/home/vscode.nix` remains a candidate to enable later if VS Code settings and extensions should be managed by Home Manager.

For this migration, the cleaner VS Code target is package-only Home Manager ownership:

- Home Manager owns the VS Code app/package.
- VS Code Settings Sync owns settings, extensions, keybindings, snippets, and profiles.
- Do not import `nix/home/vscode.nix` as-is unless the intent changes, because it currently manages extensions and user settings declaratively.

## Movable To Home Manager

These are currently in the Darwin/system layer but can be moved to Home Manager with little or no functional loss.

### Darwin System Packages

Currently in `nix/hosts/mbp/configuration.nix`:

```nix
environment.systemPackages = [
  pkgs.mkalias
  pkgs.neovim
  pkgs.tmux
  pkgs.google-chrome
];
```

Move to:

```nix
home.packages = with pkgs; [
  mkalias
  neovim
  tmux
  google-chrome
];
```

Reason: these are user-consumed tools/apps. They do not need to be installed into the system profile.

### Homebrew CLI Tools

Currently in `nix/hosts/mbp/homebrew.nix` under `homebrew.brews`.

Move most CLI tools to `home.packages`, preferably using nixpkgs packages:

- `act`
- `argocd`
- `colima`
- `docker`
- `docker-compose`
- `gnupg`
- `gpg2`
- `kubernetes-cli` or `kubectl`
- `mas`
- `node`
- `oci-cli`
- `pinentry-mac`
- `slackdump`
- `git`
- `gh`
- `woff2`
- `uv`
- `pnpm`
- `python@3.13`
- `ripgrep`
- `tree`
- `pipx`
- `bun`
- `cloudflared`

Reason: command-line packages are usually user-level. Moving them removes a large amount of routine package churn from `sudo darwin-rebuild`.

Note that some tools may still need runtime privileges for particular actions. For example, Docker or Colima may need network, VM, or socket setup depending on how they are used, but installing the CLI package itself does not need to live in the system profile.

### Ordinary GUI Apps

Currently in `nix/hosts/mbp/homebrew.nix` under `homebrew.casks`.

These remain Homebrew-managed for macOS app-bundle reliability:

- `zed`
- `brave-browser`
- `caffeine`
- `chatgpt`
- `google-chrome`
- `iina`
- `jetbrains-toolbox`
- `lens`
- `obsidian`
- `rectangle`
- `scroll-reverser`
- `slack`
- `spotify`
- `the-unarchiver`
- `visual-studio-code`
- `zoom`

Reason: Home Manager app links point into `/nix/store`, and several macOS GUI bundles failed Gatekeeper/code-signing checks or behaved poorly with Spotlight/LaunchServices from that location. Homebrew casks install real app bundles under `/Applications`, which is the more reliable path for GUI apps on this managed Mac.

Tradeoff: these app updates require the nix-darwin/Homebrew admin path.

Already moved or removed during the migration:

- `codex` moved out of the nixpkgs package set and into `nix/home/codex.nix`, which installs the official standalone CLI under `~/.local/bin` and exposes `codex-upgrade` for user-level upgrades.
- `ngrok` was already in Home Manager; the Homebrew cask was removed.
- `claude` was removed instead of migrated because this pinned nixpkgs does not provide a clean `claude` or `claude-desktop` package.

Not a clean Home Manager candidate in this pin:

- `ghostty` exists in nixpkgs but evaluates as Linux-only for this pinned `aarch64-darwin` setup.

### Dock Defaults

Currently in `nix/hosts/mbp/configuration.nix` under:

```nix
system.defaults.dock
```

Move to Home Manager using Darwin user defaults or a Home Manager activation script.

Movable settings:

- Dock orientation
- autohide
- show recents
- static-only
- tile size
- persistent apps

Reason: Dock preferences are user preferences. They do not inherently require root when targeting the current user's preference domain.

### User Fonts

Currently in `nix/hosts/mbp/configuration.nix`:

```nix
fonts.packages = with pkgs; [
  nerd-fonts.jetbrains-mono
  nerd-fonts.fira-code
];
```

Move to Home Manager by installing or linking fonts under:

```text
~/Library/Fonts
```

Reason: per-user fonts do not need system font installation.

### User Launch Agents

`nix/hosts/mbp/launchd.nix` is currently commented out and not active. If it is re-enabled, these agents should live in Home Manager instead:

- `beancount-fava`
- `beancount-commit`

Reason: they are `launchd.user.agents`, run as `hades`, and target user-owned paths such as `$HOME/ledger`.

## Must Stay System-Level

These genuinely require root or should remain in the Darwin layer.

### Hostname

Defined in `nix/hosts/mbp/configuration.nix`:

```nix
networking.hostName = "styx";
```

Reason: hostname is system networking state.

### Darwin State Version

Defined in `nix/hosts/mbp/configuration.nix`:

```nix
system.stateVersion = 5;
```

Reason: this is nix-darwin system compatibility state.

### Primary User

Defined in `nix/hosts/mbp/configuration.nix`:

```nix
system.primaryUser = "hades";
```

Reason: nix-darwin uses this to target system-level user defaults and activation behavior.

### User Account Metadata

Defined in `nix/hosts/mbp/configuration.nix`:

```nix
users.users.hades = {
  uid = 501;
  home = "/Users/hades";
  shell = pkgs.fish;
};
```

Reason: UID, home directory, and login shell are system account metadata. The interactive shell config can move to Home Manager, but changing the login shell is a system operation.

### System Shell Registration

Defined in `nix/hosts/mbp/configuration.nix`:

```nix
environment.shells = with pkgs; [ fish zsh ];
```

Reason: this manages system shell registration such as `/etc/shells`.

### Nix System Settings

Defined in `nix/hosts/mbp/configuration.nix`:

```nix
nix.enable = false;
```

and:

```nix
nix.extraOptions = ''
  auto-optimise-store = true
  experimental-features = nix-command flakes
  extra-platforms = x86_64-darwin aarch64-darwin
'';
```

Reason: Nix daemon or global Nix settings are system-level. In this repo `nix.enable = false` means nix-darwin is not currently managing `/etc/nix/nix.conf`, but changing that ownership is still a root-level decision.

### nix-homebrew

Defined in `nix/hosts/mbp/homebrew.nix`:

```nix
nix-homebrew = {
  enable = true;
  enableRosetta = true;
  user = "hades";
  autoMigrate = true;
  taps = { ... };
};
```

Reason: this manages Homebrew installation/bootstrap state, Rosetta-related setup, migration behavior, and pinned tap checkouts. This is the only Homebrew piece still tied to `sudo darwin-rebuild`, and it only changes on bootstrap or when tap inputs change.

### Homebrew Package Management

Moved to the user-scoped Home Manager profile at `nix/home/homebrew.nix` (imported by `nix/home/home.nix`).

The `taps`/`brews`/`casks` lists there are the single source of truth. A Brewfile is generated from them and applied by a `home.activation.brewBundle` script running `brew bundle --file=<generated> --cleanup`. Because nix-homebrew makes `/opt/homebrew` user-owned, this runs as `hades` with no sudo:

```bash
home-manager switch --flake ~/.config/nix#hades
```

Behavior notes:

- `--cleanup` prunes any cask/brew not in the Nix lists (replaces the former `onActivation.cleanup = "zap"`). Ad-hoc `brew install` packages not added to the lists are removed on the next switch.
- `HOMEBREW_NO_INSTALL_FROM_API=1` is preserved, so casks resolve from the pinned local tap checkout.
- `HOMEBREW_NO_AUTO_UPDATE=1` keeps switches fast; run `brew update && brew upgrade` (also sudo-free) on your own cadence.

Reason: package installs, upgrades, and cleanup are user-level once the prefix is user-owned, so they no longer need to ride inside `sudo darwin-rebuild`.

### Privileged Apps

These should not be treated as purely user-level:

- `pritunl`
- `mullvad-vpn`
- `expressvpn`
- `soundsource`
- `orbstack`
- possibly `1password`

Reason: these apps commonly install privileged helpers, LaunchDaemons, network extensions, audio/system extensions, VPN components, or files under `/Applications`, `/Library`, or `/var`.

They should either:

- stay managed by IT/MDM,
- stay in a root-run Homebrew/nix-darwin layer, or
- be updated manually during a temporary admin window.

## Pritunl Update Rule

Assume updating Pritunl requires admin access.

In this repository Pritunl is currently a Homebrew cask:

```nix
homebrew.casks = [
  "pritunl"
];
```

Updating it through the current declarative setup means running:

```bash
sudo darwin-rebuild switch --flake /Users/hades/.config/nix#styx --impure
```

Pritunl is not just a normal user app on macOS. The client uses a background service through a LaunchDaemon and places the app in `/Applications/Pritunl.app`. Its CLI is documented under:

```text
/Applications/Pritunl.app/Contents/Resources/pritunl-client
```

Useful references:

- Pritunl CLI docs: <https://docs.pritunl.com/kb/vpn/client/cli-interface>
- Pritunl release note describing the macOS LaunchDaemon service: <https://forum.pritunl.com/t/pritunl-client-v1-3-4220-57/3183>

Suggested IT wording:

> Pritunl VPN client updates require temporary admin because the macOS client installs or updates a privileged background service/LaunchDaemon and lives in `/Applications`; normal Home Manager user activation is not sufficient.

## Elevation Frequency Estimate

After moving the package lists, shell config, Dock preferences, fonts, user launch agents, and ordinary GUI apps to standalone Home Manager, the remaining Darwin layer should be very static.

Expected admin cadence:

- One initial admin window for the migration and cleanup.
- After migration, likely `0-2` admin windows per year.
- More frequent admin access only if VPN, audio driver, virtualization, security, hostname, user account, login shell, Nix daemon, or Homebrew bootstrap settings change.

Routine changes that should not need sudo after migration:

- CLI package changes
- shell config
- Git config
- editor config
- prompt config
- npm globals
- dotfiles
- most normal GUI apps
- user launch agents

## Migration Plan

The migration can start without temporary admin access. Do the Home Manager side first, keep the Darwin config unchanged during early validation, and request temp admin only for the final system cleanup.

Current status:

- `homeConfigurations.hades` exists.
- The standalone Home Manager activation package builds.
- The first user-level activation has run successfully.
- CLI/dev packages have started moving into Home Manager while Darwin/Homebrew entries remain in place for rollback safety.
- `nvim.nix` and `tmux.nix` are imported by Home Manager, so Neovim and tmux config now activate without sudo.
- `ssh.nix` is imported by Home Manager, so `~/.ssh/config` now preserves OrbStack, Colima, and 1Password agent config declaratively.
- Dock orientation, autohide, tile size, `show-recents`, and `static-only` are now applied by Home Manager.
- Fira Code and JetBrains Mono Nerd Fonts are now linked under `~/Library/Fonts/HomeManager` by Home Manager.
- Home Manager app links use `~/Applications/home-manager-apps`.
- VS Code is package-only managed by Home Manager; VS Code Settings Sync remains responsible for settings, extensions, keybindings, snippets, and profiles.
- Ordinary GUI apps are still a later batch. An initial attempt showed the GUI app closure is much larger and includes external app fetches, so that batch should be handled separately.

### Phase 1: Add Standalone Home Manager

Status: done. The standalone Home Manager output in `flake.nix` follows this shape:

```nix
homeConfigurations.hades = inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = import nixpkgs {
    system = "aarch64-darwin";
    inherit overlays;
    config.allowUnfree = true;
  };

  modules = [
    ./nix/home/home.nix
  ];
};
```

The exact implementation can share the existing `nixpkgsConfig` shape from the Darwin and WSL outputs.

Goal: make this possible:

```bash
home-manager switch --extra-experimental-features nix-command --extra-experimental-features flakes --flake /Users/hades/.config/nix#hades --impure
```

### Phase 2: Validate Without Switching

Status: done for the current CLI/dev package batch.

Build the standalone activation package first:

```bash
nix --extra-experimental-features nix-command --extra-experimental-features flakes build /Users/hades/.config/nix#homeConfigurations.hades.activationPackage --impure
```

This checks whether the standalone Home Manager graph evaluates and builds without running activation.

### Phase 3: First User-Level Activation

Status: done for the current CLI/dev package batch.

If the build passes, activate without sudo:

```bash
./result/activate
```

or:

```bash
home-manager switch --extra-experimental-features nix-command --extra-experimental-features flakes --flake /Users/hades/.config/nix#hades --impure
```

Keep the Darwin config unchanged at this stage. Temporary duplicated packages are acceptable during migration because they preserve rollback safety and avoid needing admin early.

### Phase 4: Migrate User-Scoped Items In Batches

Move one category at a time and validate after each batch.

Batch 1:

- Move `environment.systemPackages` from `nix/hosts/mbp/configuration.nix` to `home.packages`.
- Initial candidates: `mkalias`, `neovim`, `tmux`, `google-chrome`.
- Status: `mkalias`, Neovim, tmux, and CLI/dev tools are Home Manager-managed. `google-chrome` was moved back to Homebrew with the other normal GUI apps because macOS app bundles are more reliable from `/Applications` than from Home Manager symlinks into `/nix/store`.

Batch 2:

- Move Homebrew CLI brews from `nix/hosts/mbp/homebrew.nix` to `home.packages` where nixpkgs has equivalent packages.
- Keep any Homebrew-only or cask dependency package in Homebrew until proven unnecessary.

Batch 3:

- Ordinary GUI apps were tested in Home Manager-managed Nix packages or user app links, then rolled back to Homebrew.
- Status: normal GUI apps remain Homebrew/nix-darwin-managed because app bundles were more reliable from `/Applications` than from Home Manager symlinks into `/nix/store`.
- VS Code remains Homebrew-managed as a normal GUI app. VS Code Settings Sync continues to own settings, extensions, keybindings, snippets, and profiles.
- Keep `ghostty` out of this batch for now. The pinned nixpkgs package evaluated as Linux-only for `aarch64-darwin`, so Ghostty should remain Homebrew-managed unless a working Darwin package mapping is added later.

Batch 4:

- Move fonts to user font installation under `~/Library/Fonts`.
- Move Dock preferences to user-level defaults or a Home Manager activation script.
- Move any active user launch agents to Home Manager.
- Status: started. Fonts and simple Dock preferences are Home Manager-managed. Dock persistent apps remain in Darwin for now because nix-darwin has a richer `persistent-apps` option than Home Manager's typed Darwin defaults module.

After each batch:

```bash
nix --extra-experimental-features nix-command --extra-experimental-features flakes build /Users/hades/.config/nix#homeConfigurations.hades.activationPackage --impure
home-manager switch --extra-experimental-features nix-command --extra-experimental-features flakes --flake /Users/hades/.config/nix#hades --impure
```

### Phase 5: Keep Privileged Apps System-Managed

Do not move these in the first migration:

- `pritunl`
- `mullvad-vpn`
- `expressvpn`
- `soundsource`
- `orbstack`
- possibly `1password`

These may require privileged helpers, system extensions, LaunchDaemons, `/Applications`, `/Library`, or `/var` access.

### Phase 6: Final Admin Window

Request temporary admin only after Home Manager owns the user layer cleanly.

During that admin window:

1. Remove migrated packages and ordinary apps from the Darwin/Homebrew layer.
2. Keep only true system-level settings and privileged apps.
3. Run:

   ```bash
   sudo darwin-rebuild switch --flake /Users/hades/.config/nix#styx --impure
   ```

After this phase, day-to-day changes should use:

```bash
home-manager switch --extra-experimental-features nix-command --extra-experimental-features flakes --flake /Users/hades/.config/nix#hades --impure
```

Expected future admin need after cleanup: about `0-2` times per year, mostly for VPN/security/audio/virtualization apps or system account/Nix daemon changes.

## Final Admin Cleanup Checklist

Status: completed during the temporary admin window. These edits removed system/Homebrew duplicates after the Home Manager profile had already taken ownership.

Before the admin window, verify user-level ownership:

```bash
command -v nvim
command -v tmux
command -v code
command -v uv
command -v kubectl
command -v docker
command -v pnpm
defaults read com.apple.dock orientation
defaults read com.apple.dock autohide
defaults read com.apple.dock show-recents
defaults read com.apple.dock static-only
defaults read com.apple.dock tilesize
ls ~/Library/Fonts/HomeManager
ls ~/Applications/home-manager-apps
```

Expected user-level paths:

```text
/Users/hades/.nix-profile/bin/...
~/Applications/home-manager-apps
~/Library/Fonts/HomeManager
```

### `nix/hosts/mbp/configuration.nix`

Removed this system package block after confirming the Home Manager profile works:

```nix
environment.systemPackages = [
  pkgs.mkalias
  pkgs.neovim
  pkgs.tmux
  pkgs.google-chrome
];
```

These are now user-level:

- `mkalias`
- `neovim`
- `tmux`

Removed this system font block after confirming fonts are present under `~/Library/Fonts/HomeManager`:

```nix
fonts.packages = with pkgs; [
  nerd-fonts.jetbrains-mono
  nerd-fonts.fira-code
];
```

These are now user-level:

- `nerd-fonts.jetbrains-mono`
- `nerd-fonts.fira-code`

Reduced this Dock defaults block:

```nix
system.defaults.dock = {
  orientation = "left";
  autohide = true;
  show-recents = false;
  static-only = true;
  tilesize = 30;
  persistent-apps = [
    "/Applications/Windsurf.app"
    "/Applications/Google Chrome.app"
    "/Applications/Slack.app"
    "/Applications/WezTerm.app"
  ];
};
```

These Dock keys are now Home Manager-managed:

- `orientation`
- `autohide`
- `show-recents`
- `static-only`
- `tilesize`

Keep `persistent-apps` in Darwin for now unless it is intentionally replaced by a Home Manager activation script. nix-darwin has a convenient typed `persistent-apps` option; Home Manager's typed Darwin defaults module does not expose an equivalent high-level option.

Keep these system-level settings:

- `networking.hostName`
- `system.stateVersion`
- `system.primaryUser`
- `nix.enable`
- `programs.fish.enable`
- `users.users.hades`
- `nix.extraOptions`
- `environment.shells`

### `nix/hosts/mbp/homebrew.nix`

Removed these Homebrew brews after confirming Home Manager commands resolve from the user profile:

- `act`
- `argocd`
- `colima`
- `docker`
- `docker-compose`
- `gnupg`
- `gpg2`
- `kubernetes-cli`
- `mas`
- `node`
- `oci-cli`
- `pinentry-mac`
- `slackdump`
- `git`
- `gh`
- `woff2`
- `uv`
- `pnpm`
- `python@3.13`
- `tree`
- `pipx`
- `bun`
- `cloudflared`

These casks were temporarily removed during Home Manager GUI app testing, then restored to Homebrew after code-signing/Gatekeeper issues appeared:

- `visual-studio-code`
- `chatgpt`
- `slack`

This cask was removed because Home Manager owns the replacement CLI package:

- `codex`

This cask was removed because the app is no longer wanted:

- `claude`

The VS Code cask removal required clearing immutable flags first:

```bash
sudo chflags -R nouchg /Applications/Visual\ Studio\ Code.app /opt/homebrew/Caskroom/visual-studio-code
brew uninstall --cask --force visual-studio-code
```

The Claude Desktop cask removal needed the same immutable-flag cleanup pattern after Homebrew hit Electron framework symlink/chflags backup errors:

```bash
sudo chflags -R nouchg /Applications/Claude.app /opt/homebrew/Caskroom/claude
brew uninstall --cask --force claude
```

Keep these Homebrew casks system/admin-managed for now:

- `pritunl`
- `mullvad-vpn`
- `expressvpn`
- `soundsource`
- `orbstack`
- `1password`

Keep these Homebrew-managed until migrated or intentionally left as casks:

- `ghostty`
- `cmux`
- ordinary GUI apps not yet package-tested through Home Manager

### Admin Window Commands

Commands used after editing the Darwin/Homebrew files:

```bash
nixpkgs-fmt nix/hosts/mbp/configuration.nix nix/hosts/mbp/homebrew.nix
nix --extra-experimental-features nix-command --extra-experimental-features flakes flake check --no-build
sudo darwin-rebuild switch --flake /Users/hades/.config/nix#styx --impure
```

Checks used after the rebuild:

```bash
home-manager switch --extra-experimental-features nix-command --extra-experimental-features flakes --flake /Users/hades/.config/nix#hades --impure
command -v nvim tmux code uv kubectl docker pnpm
brew list --formula
brew list --cask
```

Final outcome:

- `brew list --formula` is empty.
- `brew list --cask` contains normal GUI apps and privileged/system apps: `1password`, `brave-browser`, `caffeine`, `chatgpt`, `cmux`, `expressvpn`, `ghostty`, `google-chrome`, `iina`, `jetbrains-toolbox`, `lens`, `mullvad-vpn`, `obsidian`, `orbstack`, `pritunl`, `rectangle`, `scroll-reverser`, `slack`, `soundsource`, `spotify`, `the-unarchiver`, `visual-studio-code`, `zed`, and `zoom`.
- `~/Applications/home-manager-apps` contains only `pinentry-mac.app`.
- The normal GUI apps are installed under `/Applications` by Homebrew.
- `codex` resolves from `~/.local/bin/codex` after `nix/home/codex.nix` installs OpenAI's standalone CLI.
- `codex-upgrade` resolves from the Home Manager profile and reruns the official standalone installer without sudo.
- `ngrok` resolves from the Home Manager profile.
- `/Applications/Claude.app` and `/opt/homebrew/Caskroom/claude` are gone.
