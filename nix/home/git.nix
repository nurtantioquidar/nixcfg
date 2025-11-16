{ pkgs, ... }:

let
  # Load secrets from outside the flake directory
  # This avoids the Git tracking requirement
  # NOTE: Update this path if your home directory is different
  secretsPath = /Users/hades/.config/nix-secrets/git-secrets.nix;
  secrets = if builtins.pathExists secretsPath
    then import secretsPath
    else {
      userName = "Your Name";
      userEmail = "your.email@example.com";
      sshSigningKey = "";
    };
in
{
  home.packages = with pkgs; [
    gh
  ];

  programs.git = {
    enable = true;
    lfs.enable = true;

    userName = secrets.userName;
    userEmail = secrets.userEmail;

    ignores = [
      ".DS_Store"
      "*.swp"
      "*~"
      ".idea/"
      ".vscode/"
      "*.iml"
    ];

    extraConfig = {
      # Git commit signing with 1Password
      gpg.format = "ssh";
      "gpg \"ssh\"".program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";

      user.signingkey = secrets.sshSigningKey;
      commit.gpgsign = true;

      init.defaultBranch = "main";

      pull.rebase = true;

      push.autoSetupRemote = true;

      column.ui = "auto";

      branch.sort = "-commiterdate";

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
        fscache = "falseb";
      };

      rebase = {
        autoSquash = true;
        autoStash = true;
        updateRefs = true;
      };
    };
  };
}
