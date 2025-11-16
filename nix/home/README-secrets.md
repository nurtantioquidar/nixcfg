# Secrets Setup

Git configuration requires personal information that shouldn't be committed to the repository.

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
   # - sshSigningKey: Your 1Password SSH public key (optional)
   ```

4. Rebuild:
   ```bash
   darwin-rebuild switch --flake ~/.config/nix
   ```

## Why outside the flake?

Nix flakes only see files tracked by Git. Since secrets shouldn't be committed, we store them in `~/.config/nix-secrets/` which is outside the flake directory.
