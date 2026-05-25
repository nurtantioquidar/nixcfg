{ config, lib, pkgs, ... }:

let
  # Load secrets from outside the flake directory
  # This avoids the Git tracking requirement
  # NOTE: Update this path if your home directory is different
  secretsPath =
    if pkgs.stdenv.isDarwin
    then /Users/hades/.config/nix-secrets/git-secrets.nix
    else /home/hades/.config/nix-secrets/git-secrets.nix;
  secrets =
    if builtins.pathExists secretsPath
    then import secretsPath
    else {
      userName = "Your Name";
      userEmail = "your.email@example.com";
      sshSigningKey = "";
    };
  hasSshSigningKey = secrets.sshSigningKey != "";
  enableOnePasswordSigning = pkgs.stdenv.isDarwin && hasSshSigningKey;
  allowedSignersPath = "${config.home.homeDirectory}/.config/git/allowed_signers";
in
{
  home.packages = with pkgs; [
    gh
  ];

  home.file.".config/git/allowed_signers" = lib.mkIf enableOnePasswordSigning {
    text = "${secrets.userEmail} ${secrets.sshSigningKey}\n";
  };

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

    settings = lib.mkMerge [
      {
        user = {
          name = secrets.userName;
          email = secrets.userEmail;
        };

        init.defaultBranch = "main";

        pull.rebase = true;

        push.autoSetupRemote = true;

        column.ui = "auto";

        branch.sort = "-committerdate";

        tag.sort = "version:refname";

        diff = {
          algorithm = "histogram";
          colorMoved = "plain";
          mnemonicPrefix = true;
          renames = true;
        };

        fetch = {
          prune = true;
          pruneTags = true;
          all = true;
        };

        help.autocorrect = "prompt";

        commit.verbose = true;

        rerere = {
          enabled = true;
          autoupdate = true;
        };

        core = {
          editor = "nvim";
          fscache = true;
          untrackedCache = true;
        };

        rebase = {
          autoSquash = true;
          autoStash = true;
          updateRefs = true;
        };

        gc = {
          writeCommitGraph = true;
        };

        maintenance = {
          auto = true;
        };
      }

      (lib.mkIf enableOnePasswordSigning {
        # Git commit signing with 1Password is macOS-only in this profile.
        user.signingkey = secrets.sshSigningKey;

        gpg = {
          format = "ssh";
          "ssh" = {
            allowedSignersFile = allowedSignersPath;
            program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
          };
        };

        commit.gpgsign = true;
      })
    ];
  };
}
