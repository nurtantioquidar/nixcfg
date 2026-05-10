{ pkgs, ... }:
{
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      if test -f $HOME/.env
          source $HOME/.env
      end
      
      # Set GPG_TTY using fish command substitution.
      set -x GPG_TTY (tty)

      if command -q ssh-add
          ssh-add --apple-load-keychain 2> /dev/null
      end

      fish_add_path -amP /usr/bin
      fish_add_path -amP /opt/homebrew/bin
      fish_add_path -amP /opt/local/bin
      fish_add_path -m /run/current-system/sw/bin
      fish_add_path -m $HOME/.nix-profile/bin
      fish_add_path -m $HOME/.local/bin

      # SDKMAN! initialization
      set -gx SDKMAN_DIR $HOME/.sdkman

      if test -s $SDKMAN_DIR/bin/sdkman-init.sh
          function sdk
              ${pkgs.bash}/bin/bash -c "source '$SDKMAN_DIR/bin/sdkman-init.sh' && sdk $argv"
          end
      end

      # Add SDKMAN's current Java version to PATH
      if test -d $SDKMAN_DIR/candidates/java/current/bin
          fish_add_path -m $SDKMAN_DIR/candidates/java/current/bin
      end

      # Add SDKMAN's current Maven version to PATH
      if test -d $SDKMAN_DIR/candidates/maven/current/bin
          fish_add_path -m $SDKMAN_DIR/candidates/maven/current/bin
      end
    '';

    shellAliases = {
      gds = "git diff --staged";
      gd = "git diff";
      gs = "git status";
      ll = "ls -ltra";
    };
  };
}
