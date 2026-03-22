_:
{
  programs.zsh = {
    enable = true;

    initContent = ''
      if [ -e "$HOME/.env" ]; then
        source "$HOME/.env"
      fi

      export GPG_TTY=$(tty)
      ssh-add --apple-load-keychain 2> /dev/null

      export PATH="/usr/bin:$PATH"
      export PATH="/opt/homebrew/bin:$PATH"
      export PATH="/opt/local/bin:$PATH"
      export PATH="/run/current-system/sw/bin:$PATH"
      export PATH="$HOME/.nix-profile/bin:$PATH"
      export PATH="$HOME/.local/bin:$PATH"

      # Google Cloud SDK
      source "/opt/homebrew/share/google-cloud-sdk/path.zsh.inc"
      source "/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc"

      export SDKMAN_DIR="$HOME/.sdkman"
      [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
    '';

    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;

    shellAliases = {
      gds = "git diff --staged";
      gd = "git diff";
      gs = "git status";
      ll = "ls -ltra";
    };

    oh-my-zsh = {
      enable = true;
      plugins = ["git" "sudo" "docker" "kubectl" "tmux"];
    };
  };
}
