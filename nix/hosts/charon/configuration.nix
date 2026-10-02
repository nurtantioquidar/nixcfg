{ pkgs, ... } @ args:

let
  username = "hades";
  mkImports = import ../../lib/mkImports.nix args;
in
{
  imports = mkImports {
    inherit username;
    imports = [
      ./hardware.nix
      ./disko.nix
      ./services.nix
      ./backup.nix
      ./apps/aiostreams.nix
    ];
  };

  system.stateVersion = "26.11";

  networking.hostName = "charon";
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "@wheel" ];
    allowed-users = [ "@wheel" ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Accounts are fully declarative. Nobody has a password: login is SSH keys
  # only, so console login is impossible by design.
  users.mutableUsers = false;
  users.users.${username} = {
    isNormalUser = true;
    home = "/home/${username}";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keyFiles = [ ./authorized-keys ];
  };
  # Without passwords, wheel sudo must be passwordless. SSH is the only
  # boundary, so keep it key-only and tailnet-only (see services.nix).
  security.sudo.wheelNeedsPassword = false;

  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];
  environment.systemPackages = with pkgs; [
    curl
    git
    htop
    jq
    neovim
    ripgrep
    tmux
    unzip
  ];

  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 4 * 1024;
  }];

  boot.tmp.cleanOnBoot = true;
  services.journald.extraConfig = "SystemMaxUse=1G";
}
