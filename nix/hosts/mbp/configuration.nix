{ pkgs, ... } @ args:

let
  username = "hades";
  mkImports = import ../../lib/mkImports.nix args;
in
{
  system.stateVersion = 5;

  imports = mkImports {
    inherit username;

    imports = [
      ./homebrew.nix
      # ./launchd.nix
    ];
  };

  system.primaryUser = "hades";

  nix.enable = false;

  environment.shells = with pkgs; [ fish zsh ];
  environment.systemPackages =
    [
      pkgs.mkalias
      pkgs.neovim
      pkgs.tmux
      pkgs.google-chrome
    ];

  programs.fish.enable = true;

  users.users.hades = {
    uid = 501;
    home = "/Users/hades";
    shell = pkgs.fish;
  };

  nix.extraOptions = ''
    auto-optimise-store = true
    experimental-features = nix-command flakes
    extra-platforms = x86_64-darwin aarch64-darwin
  '';

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
