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
      # Git commit signing with 1Password
      user = {
        name = secrets.userName;
        email = secrets.userEmail;
        signingkey = secrets.sshSigningKey;
      };

      gpg = {
        format = "ssh";
        "ssh".program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      };

      commit.gpgsign = true;

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
    };
  };
}
