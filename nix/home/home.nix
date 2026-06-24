{ pkgs, lib, ... }:

let
  vscodeCode = pkgs.writeShellScriptBin "code" ''
    exec "/Users/hades/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" "$@"
  '';
in
{
  imports = [
    # ./vscode.nix
    ./git.nix
    ./zsh.nix
    ./fish.nix
    ./bash.nix
    ./claude-code.nix
    ./codex.nix
    ./ghostty.nix
    ./homebrew.nix
    ./node-packages.nix
    ./ssh.nix
    ./nvim.nix
    ./tmux.nix
    ./zellij.nix
  ];

  home = {
    stateVersion = "25.05";
    file.".config/wezterm/wezterm.lua".source = ../dotfiles/wezterm.lua;

    packages = with pkgs; [
      htop
      curl
      coreutils
      jq
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      ripgrep
      ngrok
      unzip
      zip
      go
      gopls
      delve
      mockgen
      google-cloud-sdk
    ] ++ lib.optionals pkgs.stdenv.isDarwin [
      act
      argocd
      bun
      cloudflared
      colima
      docker
      docker-compose
      gnupg
      kubectl
      mas
      mkalias
      oci-cli
      pinentry_mac
      pipx
      pnpm
      python313
      slackdump
      tree
      uv
      vscodeCode
      woff2
    ];

    # Ensure ~/.local/bin is on PATH for all processes (not just interactive shells)
    # This fixes warnings from tools like `uv` that check PATH in non-interactive contexts
    sessionVariables = {
      PATH = "$HOME/.local/bin:$PATH";
    } // lib.optionalAttrs pkgs.stdenv.isDarwin {
      EDITOR = "zed --wait";
      VISUAL = "zed --wait";
      GIT_EDITOR = "zed --wait";
    };

    activation.installSdkman = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d "$HOME/.sdkman" ]; then
        export PATH="${pkgs.unzip}/bin:${pkgs.zip}/bin:${pkgs.curl}/bin:${pkgs.gnutar}/bin:${pkgs.gzip}/bin:$PATH"
        $DRY_RUN_CMD ${pkgs.curl}/bin/curl -s "https://get.sdkman.io?rcupdate=false" | $DRY_RUN_CMD ${pkgs.bash}/bin/bash
      fi
    '';

    activation.configureDock = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ "$(uname -s)" = "Darwin" ]; then
        $DRY_RUN_CMD /usr/bin/defaults write com.apple.dock show-recents -bool false
        $DRY_RUN_CMD /usr/bin/defaults write com.apple.dock static-only -bool true
      fi
    '';
  };

  programs = {
    home-manager.enable = true;

    dircolors = {
      enable = true;
    };

    direnv.enable = true;

    starship = {
      enable = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      settings = {
        add_newline = true;
        command_timeout = 500;
        scan_timeout = 10;

        # Custom prompt format
        format = "$username$hostname$directory$git_branch$git_status$character";

        # Character configuration
        character = {
          success_symbol = "[➜](bold bright-green)";
          error_symbol = "[✗](bold bright-red)";
        };

        # Directory configuration
        directory = {
          truncation_length = 3;
          truncate_to_repo = true;
          style = "bold bright-cyan";
        };

        # Git branch
        git_branch = {
          symbol = " ";
          style = "bold bright-magenta";
        };

        # Git status
        git_status = {
          disabled = true;
          style = "bold bright-yellow";
          ahead = "⇡\${count}";
          behind = "⇣\${count}";
          diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
          conflicted = "🏳";
          deleted = "🗑";
          renamed = "📛";
          modified = "📝";
          staged = "[++($count)](bright-green)";
          untracked = "[??($count)](bright-red)";
        };

        # Username
        username = {
          show_always = false;
          style_user = "bold bright-yellow";
          format = "[$user]($style)@";
        };

        # Hostname
        hostname = {
          ssh_only = true;
          style = "bold bright-green";
          format = "[$hostname]($style):";
        };

        # Language/tool versions
        nodejs = {
          symbol = " ";
          style = "bold bright-green";
          format = "via [$symbol($version )]($style)";
        };

        python = {
          symbol = " ";
          style = "bold bright-yellow";
          format = "via [$symbol($version )]($style)";
        };

        java = {
          symbol = " ";
          style = "bold bright-red";
          format = "via [$symbol($version )]($style)";
        };

        docker_context = {
          symbol = " ";
          style = "bold bright-blue";
          format = "via [$symbol$context]($style) ";
        };

        kubernetes = {
          symbol = "☸ ";
          style = "bold bright-blue";
          format = "on [$symbol$context( \\($namespace\\))]($style) ";
          disabled = false;
        };
      };
    };
  };

  targets.darwin.linkApps = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    directory = "Applications/home-manager-apps";
  };

  targets.darwin.defaults = lib.mkIf pkgs.stdenv.isDarwin {
    "com.apple.dock" = {
      orientation = "left";
      autohide = true;
      tilesize = 30;
    };
  };
}
