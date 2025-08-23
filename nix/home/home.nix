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
    # ./git.nix
    # ./zsh.nix
    ./fish.nix
    # ./fonts.nix  # Now using system-level fonts.packages instead
    # ./ssh.nix
    # ./nvim.nix
    # ./tmux.nix
  ];

  programs.dircolors = {
    enable = true;
  };

  programs.direnv.enable = true;
}
