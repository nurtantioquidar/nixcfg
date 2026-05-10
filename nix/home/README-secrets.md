# Secrets Setup

Git configuration requires personal information that shouldn't be committed to the repository. `nix/home/git.nix` reads those values from an external file:

- macOS: `/Users/hades/.config/nix-secrets/git-secrets.nix`
- WSL: `/home/hades/.config/nix-secrets/git-secrets.nix`

## Setup Instructions

1. Create the secrets directory:
   ```bash
   mkdir -p ~/.config/nix-secrets
   ```

2. Copy the template:
   ```bash
   cp nix/home/secrets.nix.template ~/.config/nix-secrets/git-secrets.nix
   ```

3. Edit with your information:
   ```bash
   # Edit the file
   nvim ~/.config/nix-secrets/git-secrets.nix

   # Add your actual values:
   # - userName: Your Git username
   # - userEmail: Your Git email
   # - sshSigningKey: Your 1Password SSH public key (optional, macOS only)
   ```

4. Rebuild:
   ```bash
   sudo darwin-rebuild switch --flake ~/.config/nix#styx
   ```

## Why outside the flake?

Nix flakes only see files tracked by Git. Since secrets shouldn't be committed, we store them in `~/.config/nix-secrets/` which is outside the flake directory. If your home directory changes, update `secretsPath` in `nix/home/git.nix` to the new absolute path.

On macOS, 1Password commit signing is enabled only when `sshSigningKey` is non-empty. On WSL, the 1Password signing settings are intentionally omitted.
