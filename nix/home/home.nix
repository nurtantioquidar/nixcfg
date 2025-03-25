{ pkgs, ... }:

{
  home.stateVersion = "25.05";

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
    # ./ssh.nix
    # ./nvim.nix
    # ./tmux.nix
  ];

  programs.dircolors = {
    enable = true;
  };

  programs.direnv.enable = true;
}
