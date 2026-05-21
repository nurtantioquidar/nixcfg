# Secrets Setup

Git configuration requires personal information that should not be committed to this repository. `nix/home/git.nix` reads those values from an external file:

- macOS: `/Users/hades/.config/nix-secrets/git-secrets.nix`
- WSL: `/home/hades/.config/nix-secrets/git-secrets.nix`

## Setup Instructions

Run these commands from the repository root unless noted otherwise.

1. Create the secrets directory.

   ```bash
   mkdir -p ~/.config/nix-secrets
   ```

2. Copy the template.

   ```bash
   cp ~/.config/nix/nix/home/secrets.nix.template ~/.config/nix-secrets/git-secrets.nix
   ```

3. Edit the external secrets file.

   ```bash
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

   Use an empty string for `sshSigningKey` if 1Password Git commit signing should stay disabled.

4. Verify that Nix can import the file.

   ```bash
   nix-instantiate --eval -E 'import /Users/hades/.config/nix-secrets/git-secrets.nix'
   ```

   On WSL:

   ```bash
   nix-instantiate --eval -E 'import /home/hades/.config/nix-secrets/git-secrets.nix'
   ```

5. Rebuild the relevant host.

   macOS:

   ```bash
   sudo darwin-rebuild switch --flake /Users/hades/.config/nix#styx --impure
   ```

   WSL:

   ```bash
   sudo nixos-rebuild switch --flake ~/.config/nix#wsl
   ```

6. Verify the effective Git configuration.

   ```bash
   git config --get user.name
   git config --get user.email
   git config --get gpg.format
   git config --get gpg.ssh.program
   git config --get user.signingkey
   git config --get commit.gpgsign
   ```

## Why outside the flake?

Nix flakes only see files tracked by Git. Since secrets should not be committed, store them in `~/.config/nix-secrets/`, outside the flake directory.

If the username or home directory changes, update `secretsPath` in `nix/home/git.nix`.

## 1Password Signing

On macOS, 1Password commit signing is enabled only when `sshSigningKey` is non-empty. On WSL, the 1Password signing settings are intentionally omitted.

For GitHub verification, add the same public key to GitHub as a signing key, not only as an authentication key. The commit email must also match an email on the GitHub account.
