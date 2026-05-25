# Agent Guide

This repository manages personal Nix configuration for macOS and WSL.

## Scope

- macOS host: `darwinConfigurations.styx`
- WSL host: `nixosConfigurations.wsl`
- Shared Home Manager profile: `nix/home/home.nix`
- Primary reference docs: `docs/setup-guide.md`

## Working Rules

- Prefer the existing Nix module layout over introducing new structure.
- Keep host-specific changes under `nix/hosts/mbp` or `nix/hosts/wsl`.
- Keep host-specific helper scripts under `nix/hosts/<host>/scripts`.
- Keep shared user packages, shells, Git, prompt, and dotfile behavior under `nix/home`.
- Keep local secrets outside this flake. The expected external secrets path is documented in `docs/setup-guide.md`.
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

For WSL:

```bash
sudo nixos-rebuild switch --flake ~/.config/nix#wsl
```

## Homebrew Notes

Homebrew is managed through `nix-homebrew` and `nix/hosts/mbp/homebrew.nix`.

- Keep `homebrew/cask` in `homebrew.taps`.
- Keep `inputs.homebrew-cask` exposed through `nix-homebrew.taps."homebrew/homebrew-cask"`.
- Keep `manaflow-ai/cmux` in `homebrew.taps` and expose `inputs.homebrew-cmux` through `nix-homebrew.taps."manaflow-ai/homebrew-cmux"` for the cmux cask.
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
