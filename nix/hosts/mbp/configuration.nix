{ pkgs, ... } @ args:

let
  username = "hades";
  mkImports = import ../../lib/mkImports.nix args;
in
{
  imports = mkImports {
    inherit username;

    imports = [
      ./homebrew.nix
      # ./launchd.nix
    ];
  };

  networking = {
    hostName = "MAC-F0Q3XN9HR9";
    localHostName = "MAC-F0Q3XN9HR9";
    computerName = "MAC-F0Q3XN9HR9";
  };

  system = {
    stateVersion = 5;
    primaryUser = "hades";

    defaults = {
      dock = {
        persistent-apps = [
          "/Applications/Windsurf.app"
          "/Applications/Google Chrome.app"
          "/Applications/Slack.app"
          "/Applications/WezTerm.app"
        ];
      };
    };
  };

  nix.enable = false;

  environment.shells = with pkgs; [ fish zsh ];

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
}
