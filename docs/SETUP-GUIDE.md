# Nix Setup Guide

This repository manages two flake outputs:

- `darwinConfigurations.styx` for the macOS host.
- `nixosConfigurations.wsl` for the NixOS-WSL host.

Darwin is the primary path in this guide. WSL uses the same Home Manager profile where practical.

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
sudo darwin-rebuild switch --flake ~/.config/nix#styx
sudo nixos-rebuild switch --flake ~/.config/nix#wsl
```

With flakes, local changes must be visible to Git before a rebuild can read them. Stage or commit changed files first when a rebuild says a path is missing from the source tree.

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

## 1Password Git Signing

The macOS Git signing setup is enabled only when `sshSigningKey` is configured:

- `gpg.format = "ssh"`
- `gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"`
- `user.signingkey = secrets.sshSigningKey`
- `commit.gpgsign = true`

Enable the 1Password SSH agent in the 1Password macOS app, create or choose an SSH key, copy its public key, and put that public key in `sshSigningKey` in `/Users/hades/.config/nix-secrets/git-secrets.nix`.

For GitHub verification, add the same public key at `https://github.com/settings/keys` as a signing key, not only as an authentication key.

After rebuilding, verify the effective Git configuration:

```bash
git config --get gpg.format
git config --get gpg.ssh.program
git config --get user.signingkey
git config --get commit.gpgsign
./verify-1password-signing.sh
```

The verification script creates a temporary repository with `mktemp`, attempts a signed test commit there, and cleans it up automatically, so it does not require modifying repository files.

## SSH Agent Configuration

`nix/home/ssh.nix` contains a Home Manager SSH config for the 1Password agent, but `nix/home/home.nix` does not currently import it. Keep using manual SSH config unless you intentionally enable that module.

Manual macOS SSH config:

```sshconfig
Host *
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
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

`nix/hosts/mbp/homebrew.nix` lets Homebrew update during activation and sets `HOMEBREW_NO_INSTALL_FROM_API=1` for `brew bundle`. This avoids failures in Homebrew's cask API loader, such as `undefined method 'to_sym' for nil`, while still letting nix-darwin manage the Brewfile.

### A Cask Vendor Download Fails

If one cask download returns a vendor-side HTTP error, `brew bundle` fails the whole activation. Keep that app out of `homebrew.casks` until the vendor URL is healthy again, then install it manually or re-enable it in `nix/hosts/mbp/homebrew.nix`.

CLI tools are usually better managed through Nix when possible. For example, Google Cloud SDK is installed as `google-cloud-sdk` through Home Manager instead of the Homebrew `gcloud-cli` cask, avoiding Caskroom upgrade state failures during activation.

### Homebrew Cleanup Refuses To Uninstall Dependencies

This config uses `homebrew.onActivation.cleanup = "zap"` so unmanaged Homebrew packages are pruned during activation. If cleanup refuses to uninstall a formula because an installed cask still depends on it, keep that formula in `homebrew.brews`; for example, `python@3.13` and `ripgrep` are listed because Homebrew reported them as live cask dependencies.

### NPM Deprecation Warnings During Rebuild

`nix/home/node-packages.nix` manages selected global npm packages under `~/.local`. The activation checks whether each package is already installed before running `npm install --global`, so transitive npm warnings should appear only when a package is missing and installation actually runs.

### Starship Looks Unchanged

Open a new terminal, confirm the active shell is loading Home Manager output, and check that Starship is installed:

```bash
which starship
echo $SHELL
```

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
git config --get user.signingkey
git config --get commit.gpgsign
```

If these values are missing on macOS, rebuild the flake and confirm the secrets file contains `sshSigningKey`. On WSL, the 1Password signing values are intentionally omitted.

### Flake Commands Fail Before Rebuild

If `nix flake ...` fails with `experimental Nix feature 'nix-command' is disabled`, run the command with explicit feature flags:

```bash
nix --extra-experimental-features nix-command --extra-experimental-features flakes flake check --no-build
```

On the Darwin host, this flake currently sets `nix.enable = false`, so nix-darwin is not the component managing `/etc/nix/nix.conf`. Enable `nix-command` and `flakes` in the external Nix installation, or keep passing the explicit feature flags.

### GitHub Shows Unverified

Confirm the public key in `sshSigningKey` is added to GitHub as a signing key and that the commit email matches an email on the GitHub account.
