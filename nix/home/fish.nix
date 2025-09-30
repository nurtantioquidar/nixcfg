_:
{
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      if test -f $HOME/.env
          source $HOME/.env
      end
      
      # Set GPG_TTY using fish command substitution.
      set -x GPG_TTY (tty)

      ssh-add --apple-load-keychain 2> /dev/null

      fish_add_path -amP /usr/bin
      fish_add_path -amP /opt/homebrew/bin
      fish_add_path -amP /opt/local/bin
      fish_add_path -m /run/current-system/sw/bin
      fish_add_path -m $HOME/.nix-profile/bin
      fish_add_path -m $HOME/.local/bin

      # SDKMAN! initialization
      set -gx SDKMAN_DIR (brew --prefix sdkman-cli)/libexec

      function sdk
          bash -c "source '$SDKMAN_DIR/bin/sdkman-init.sh' 2>/dev/null && sdk $argv"
      end

      function fish_prompt
          set -l level $SHLVL
          set -l usr (whoami)
          set -l branch ""
          # If inside a git repository, grab the branch name.
          if command git rev-parse --is-inside-work-tree > /dev/null 2>&1
              set branch (git symbolic-ref --short HEAD 2>/dev/null)
              if test -n "$branch"
                  set branch " ($branch)"
              end
          end
          set -l pwd (prompt_pwd)
          # Build the prompt as a single string.
          set -l prompt (string join "" (set_color cyan) $level ":" $usr (set_color magenta) $branch (set_color normal) " " $pwd " > ")
          echo -n $prompt
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
