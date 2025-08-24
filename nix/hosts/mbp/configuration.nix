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

  networking.hostName = "styx";

  system.defaults = {
    dock = {
      orientation = "left";
      autohide = true;
      show-recents = false;
      static-only = true;
      tilesize = 30;
      persistent-apps = [
        "/Applications/Windsurf.app"
        "/Applications/Google Chrome.app"
        "/Applications/Slack.app"
        "/Applications/WezTerm.app"
      ];
    };
  };

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

  # Enable proper font directory management
  fonts.enableFontDir = true;
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    atlassian-fonts
  ];
}
