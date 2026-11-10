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
    ];
  };

  networking = {
    hostName = "MAC-YP2JJ9KNWT";
    localHostName = "MAC-YP2JJ9KNWT";
    computerName = "MAC-YP2JJ9KNWT";
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

  # Installs the 1Password CLI at /usr/local/bin/op, the only path the 1Password app's CLI
  # integration accepts; a Nix store or Home Manager copy falls back to master-password sign-in.
  programs._1password.enable = true;

  users.users.hades = {
    uid = 503;
    home = "/Users/hades";
    shell = pkgs.fish;
  };

  nix.extraOptions = ''
    auto-optimise-store = true
    experimental-features = nix-command flakes
    extra-platforms = x86_64-darwin aarch64-darwin
  '';
}
