# Agent Guide

This repository manages personal Nix configuration for macOS and WSL.

## Scope

- macOS host: `darwinConfigurations.styx`
- WSL host: `nixosConfigurations.wsl`
- Standalone macOS Home Manager profile: `homeConfigurations.hades`
- Shared Home Manager profile: `nix/home/home.nix`
- Primary reference docs: `docs/setup-guide.md`

## Working Rules

- Prefer the existing Nix module layout over introducing new structure.
- Keep host-specific changes under `nix/hosts/mbp` or `nix/hosts/wsl`.
- Keep host-specific helper scripts under `nix/hosts/<host>/scripts`.
- Keep shared user packages, shells, Git, prompt, and dotfile behavior under `nix/home`.
- Keep Codex CLI user-managed through `nix/home/codex.nix`; use `codex-upgrade` to rerun OpenAI's standalone installer without sudo.
- Keep Zellij user-managed through `nix/home/zellij.nix`. Its wrapper intentionally normalizes `TMPDIR` outside direnv/Nix `nix-shell.*` temp directories and downgrades Ghostty's outer `TERM` to avoid leaked DSR responses like `?997;2n` when launching Zellij from this repo. The same module also writes Ghostty config on macOS so the left Option key behaves as terminal Alt for Zellij bindings. For Zellij prompts that show `<Del>` on Mac keyboards, use `Fn+Delete`; Ghostty cannot bind `fn` directly.
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

Do not rely on hostname inference. This Mac may report a hostname that does not match the flake output name.

For user-level macOS Home Manager changes, validate and switch the standalone profile without sudo:

```bash
nix --extra-experimental-features nix-command --extra-experimental-features flakes build /Users/hades/.config/nix#homeConfigurations.hades.activationPackage --impure
home-manager switch --extra-experimental-features nix-command --extra-experimental-features flakes --flake /Users/hades/.config/nix#hades --impure
```

Keep root-required macOS settings in `darwinConfigurations.styx`; move user packages, shells, Git, prompt, and dotfile behavior through `homeConfigurations.hades` when possible.

For WSL:

```bash
sudo nixos-rebuild switch --flake ~/.config/nix#wsl
```

## Homebrew Notes

Homebrew bootstrap, pinned taps, and privileged casks are managed through `nix-homebrew` and `nix/hosts/mbp/homebrew.nix`.

- Keep `homebrew/cask` in `homebrew.taps`.
- Keep `inputs.homebrew-cask` exposed through `nix-homebrew.taps."homebrew/homebrew-cask"`.
- Keep `manaflow-ai/cmux` in `homebrew.taps` and expose `inputs.homebrew-cmux` through `nix-homebrew.taps."manaflow-ai/homebrew-cmux"` for the cmux cask.
- Keep ordinary app-bundle casks out of Darwin `homebrew.casks`; declare them in `nix/home/homebrew.nix` instead. Home Manager writes a user Brewfile and runs `brew bundle install --no-upgrade` with `HOMEBREW_CASK_OPTS=--appdir=/Users/hades/Applications`. Casks with package installers or privileged components may still need the admin path.
- Do not enable automatic `brew bundle cleanup` in the user Homebrew module; cleanup sees all Homebrew casks, including privileged casks owned by the Darwin profile.
- Keep `homebrew.onActivation.cleanup = "none"` unless intentionally pruning user-installed Homebrew apps.
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
