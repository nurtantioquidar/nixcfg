{ pkgs, ... }:

{
  home.stateVersion = "25.05";
  home.file.".config/wezterm/wezterm.lua".source = ../dotfiles/wezterm.lua;

  home.packages = with pkgs; [
    htop
    curl
    coreutils
    jq
    ripgrep
    ngrok
  ];

  imports = [
    # ./vscode.nix
    ./git.nix
    # ./zsh.nix
    ./fish.nix
    ./bash.nix
    # ./ssh.nix
    # ./nvim.nix
    # ./tmux.nix
  ];

  programs.dircolors = {
    enable = true;
  };

  programs.direnv.enable = true;

  # Ensure ~/.local/bin is on PATH for all processes (not just interactive shells)
  # This fixes warnings from tools like `uv` that check PATH in non-interactive contexts
  home.sessionVariables = {
    PATH = "$HOME/.local/bin:$PATH";
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
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
}
