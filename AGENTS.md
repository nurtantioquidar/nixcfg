# Agent Guide

This repository manages personal Nix configuration for macOS and WSL.

## Scope

- Personal MacBook Pro: `darwinConfigurations.styx`, also exposed as `darwinConfigurations.MAC-F0Q3XN9HR9`, account `hades` UID 501. This former company laptop is personally owned through the laptop ownership program.
- Company MacBook Air: `darwinConfigurations.MAC-YP2JJ9KNWT`, account `hades` UID 503. It is work-only and must not use the personal `styx` alias.
- The MBP and MBA intentionally share the full `nix/home/home.nix` Home Manager profile and currently mirror the same privileged Homebrew baseline. Keep their host modules separate so they can diverge later without changing host identity or UID handling.
- Mac mini server: `darwinConfigurations.luna`, account `kerberos`; see `docs/luna-setup.md`.
- WSL host: `nixosConfigurations.wsl`
- Standalone macOS Home Manager profile: `homeConfigurations.hades`
- Shared Home Manager profile: `nix/home/home.nix`
- Primary reference docs: `docs/setup-guide.md`

## Working Rules

- Prefer the existing Nix module layout over introducing new structure.
- Keep host-specific changes under `nix/hosts/mbp`, `nix/hosts/mba`, `nix/hosts/mac-mini`, or `nix/hosts/wsl`.
- Luna uses the minimal `nix/home/server.nix` profile; do not import the laptop's desktop apps or hard-coded hades secrets into it. Its Home Manager is activated through the Darwin output.
- Luna uses upstream Nix managed by nix-darwin, the Nix Tailscale system daemon (not Tailscale.app), and Colima as a system LaunchDaemon running as kerberos. Verify boot without GUI login on the actual mini before claiming unattended readiness.
- First luna activation must run at its console with a valid authorized_keys already installed: SSH is restricted to Tailscale source ranges. FileVault and automatic login are manual owner decisions; no change to either is implied by activation. GUI agents need a separate session/permissions design.
- Validate luna with `nix build .#darwinConfigurations.luna.system --no-link` (plus feature flags if needed); activate only on the mini with `sudo darwin-rebuild switch --flake /Users/kerberos/.config/nix#luna`. Use a `path:` flake URL when validating new untracked modules.
- Keep host-specific helper scripts under `nix/hosts/<host>/scripts`.
- Keep shared user packages, shells, Git, prompt, and dotfile behavior under `nix/home`.
- Keep shared host import wiring in `nix/lib/mkImports.nix`; prefer updating host module lists over bypassing the helper.
- Keep custom package overrides in `nix/overlays` and reusable local package definitions in `nix/packages`; expose new packages through `nix/overlays/default.nix`.
- Keep Codex CLI user-managed through `nix/home/codex.nix`; use `codex-upgrade` to rerun OpenAI's standalone installer without sudo.
- Keep Herdr user-managed through the pinned upstream flake input and `nix/home/herdr.nix`; update it with `nix flake update herdr` and rebuild Home Manager. Its config and wrapper are also owned by that module: mouse capture stays enabled for pane navigation, while the wrapper clears host mouse-reporting modes after Herdr exits so they cannot leak into the parent shell.
- Keep global npm package management in `nix/home/node-packages.nix`. That module writes `~/.npmrc` so `npm install --global` uses the user-writable `~/.local` prefix instead of the immutable Nix store. Home Manager installs missing packages without upgrading existing ones; use `node-packages-upgrade` for an explicit update of all declared global npm packages.
- Keep Ghostty user-managed through the `ghostty` cask in `nix/home/homebrew.nix`, with its configuration in `nix/home/ghostty.nix`.
- Both MacBooks use Apple's `container` runtime and Opossum for Compose projects. The Opossum cask in `nix/home/homebrew.nix` pulls in Homebrew's `container` formula; keep its tap pinned in both laptop Homebrew modules and trust only the exact Opossum cask. Do not reintroduce OrbStack, Colima, or Docker CLI packages into the shared laptop profile. Luna's Colima/Docker setup and WSL Docker remain separate. See `docs/apple-container.md` for setup and limitations.
- After a Darwin rebuild moves Home Manager packages into `/etc/profiles/per-user/hades`, an already-open zsh prompt may still call the old `~/.nix-profile/bin/starship`. If the rebuild process has exited, restart that shell with `exec zsh -l`; a fresh shell resolves Starship from the new profile.
- Ghostty currently forces zsh shell integration in the shared Home Manager profile. If a host switches its Ghostty shell to fish, update this setting to match; the Darwin laptop modules currently declare fish as the user shell.
- Keep Zed user-managed through the `zed` cask in `nix/home/homebrew.nix`, with settings and Geist fonts in `nix/home/zed.nix`. The Zed module copies Geist font files into the top level of `~/Library/Fonts` during Home Manager activation; packaging the font alone leaves it under a nested `HomeManager` directory.
- Keep Zellij user-managed through `nix/home/zellij.nix`. Its wrapper intentionally normalizes `TMPDIR` outside direnv/Nix `nix-shell.*` temp directories, sets `ZELLIJ_SOCKET_DIR` to a short per-user `/tmp` path to avoid macOS socket path limits, and downgrades Ghostty's outer `TERM` to avoid leaked DSR responses like `?997;2n` when launching Zellij from this repo. Ghostty config sets the left Option key as terminal Alt for Zellij bindings while the right Option key remains available for macOS character input. Zellij clears default bindings so `Alt+Left`/`Alt+Right` stay available for shell word navigation, and `nix/home/zsh.nix` binds the common Option+Arrow escape sequences to zsh word movement so trailing `C`/`D` bytes are not inserted. `Alt+Shift+f` toggles floating panes, `Alt+Shift+n` opens a tab, and `Ctrl+y` launches zellij-forgot. The zellij-autolock plugin is defined but intentionally not loaded because upstream issue fresh2dev/zellij-autolock#20 reports that it can immediately undo manual `Ctrl+g` lock/unlock changes. For Zellij prompts that show `<Del>` on Mac keyboards, use `Fn+Delete`; Ghostty cannot bind `fn` directly.
- Keep the VS Code CLI user-scoped on macOS. Home Manager installs a `code` wrapper for `/Users/hades/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code` because this machine previously had VS Code ownership and app-bundle issues when moving between Homebrew, Home Manager app links, and system locations.
- Keep local secrets outside this flake. The expected external secrets path is documented in `docs/setup-guide.md`.
- Git SSH signing verification is managed through Home Manager. `nix/home/git.nix` writes `~/.config/git/allowed_signers` from the external `userEmail` and `sshSigningKey` values when 1Password signing is enabled.
- Do not mutate Nix store paths or Nix-managed Homebrew tap symlinks directly. Change flake inputs or Nix modules instead.
- Use `rg` for repository search.
- Use `nixpkgs-fmt` for Nix formatting when editing Nix files.
- Markdown documentation filenames must be lower kebab case. `AGENTS.md` is the only exception.

## Build And Validation

Run lightweight evaluation before handing off meaningful config changes:

```bash
nix --extra-experimental-features nix-command --extra-experimental-features flakes flake check --no-build
```

For the Darwin host, select the configured host explicitly:

```bash
sudo darwin-rebuild switch --flake /Users/hades/.config/nix#styx --impure
```

The personal MacBook Pro hostname is also exposed as `#MAC-F0Q3XN9HR9`; keep `#styx` as its friendly alias. Use only `#MAC-YP2JJ9KNWT` for the company MacBook Air.

For user-level macOS Home Manager changes, validate the standalone profile without sudo:

```bash
nix --extra-experimental-features nix-command --extra-experimental-features flakes build /Users/hades/.config/nix#homeConfigurations.hades.activationPackage --impure
```

Activate the standalone profile only when the change should be applied to the user environment:

```bash
home-manager switch --extra-experimental-features nix-command --extra-experimental-features flakes --flake /Users/hades/.config/nix#hades --impure
```

Keep root-required macOS settings in the applicable MacBook Darwin configuration; move user packages, shells, Git, prompt, and dotfile behavior through `homeConfigurations.hades` when possible.

For WSL:

```bash
sudo nixos-rebuild switch --flake ~/.config/nix#wsl
```

## Homebrew Notes

Homebrew bootstrap, pinned taps, and privileged casks are managed per laptop through `nix-homebrew` and the applicable `nix/hosts/mbp/homebrew.nix` or `nix/hosts/mba/homebrew.nix` module.

- Keep `homebrew/cask` in `homebrew.taps`.
- Keep `inputs.homebrew-cask` exposed through `nix-homebrew.taps."homebrew/homebrew-cask"`.
- Keep `manaflow-ai/cmux` in `homebrew.taps` and expose `inputs.homebrew-cmux` through `nix-homebrew.taps."manaflow-ai/homebrew-cmux"` for the cmux cask.
- Trust only the exact Tinycast, cmux, AeroSpace, and Opossum casks through `nix-homebrew.trust.casks`; do not trust their complete third-party taps.
- Keep Tinycast user-managed through `nix/home/homebrew.nix`; expose `inputs.homebrew-tinycast` through `nix-homebrew.taps."abue-ammar/homebrew-tinycast"` for its pinned third-party cask. Trust only the exact declared third-party casks during activation, not their full taps, and keep launcher preferences in `nix/home/tinycast.nix` so the user-owned Claude app wins duplicate bundle-ID resolution.
- Keep AeroSpace fully user-managed through its official cask and tap in `nix/home/homebrew.nix`; expose `inputs.homebrew-aerospace` through `nix-homebrew.taps."nikitabobko/homebrew-tap"` so its cask stays pinned. Its configuration lives in `nix/home/aerospace.nix`; app updates must not require admin access after the pinned tap has been bootstrapped by Darwin.
- Keep Opossum user-managed through its cask in `nix/home/homebrew.nix`; expose `inputs.homebrew-opossum` through `nix-homebrew.taps."suruseas/homebrew-opossum"` in both laptop modules. The cask depends on Homebrew's Apple `container` formula. Trust only `suruseas/opossum/opossum`, not the whole tap.
- Keep ordinary app-bundle casks out of Darwin `homebrew.casks`; declare them in `nix/home/homebrew.nix` instead. Home Manager writes a user Brewfile and runs `brew bundle install --no-upgrade` with `HOMEBREW_CASK_OPTS=--appdir=/Users/hades/Applications`. Casks with package installers or privileged components may still need the admin path.
- Keep `HOMEBREW_CASK_OPTS` scoped to the user Home Manager activation rather than exporting it as a session variable. A global value also redirects Darwin-managed casks such as 1Password into the user Applications directory; 1Password belongs at `/Applications/1Password.app`.
- Do not enable automatic `brew bundle cleanup` in the user Homebrew module; cleanup sees all Homebrew casks, including privileged casks owned by the Darwin profile.
- Keep `homebrew.onActivation.cleanup = "none"` unless intentionally pruning user-installed Homebrew apps.
- Treat cask ownership changes as state-changing: removing a cask from the user-managed list can uninstall it during Home Manager activation unless it is explicitly exempted or moved through an approved admin/user flow. For audit-only work, report drift without changing cask membership.
- Activation sets `HOMEBREW_NO_INSTALL_FROM_API=1`, so cask behavior should be checked with the no-API path when debugging casks.
- If a cask DSL error appears, consider whether `nix-homebrew`, its `brew-src`, and `homebrew-cask` are pinned to compatible revisions.

## Documentation Maintenance

Update this file whenever a change meaningfully alters how future agents should work in this repo.

A meaningful change includes:

- adding, removing, or renaming flake outputs, hosts, modules, or major directories;
- changing rebuild, validation, formatting, or activation commands;
- changing Homebrew management, cask resolution, or cleanup behavior;
- changing where secrets, dotfiles, shells, Git signing, or shared Home Manager configuration live;
- adding a new recurring troubleshooting rule or operational pitfall.
- changing documentation naming conventions.

Small package list edits, version bumps, and lock-file refreshes usually do not need an `AGENTS.md` update unless they change the workflow above.
