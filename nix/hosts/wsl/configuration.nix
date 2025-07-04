{ pkgs, ... } @ args:

let
  username = "hades";
  mkImports = import ../../lib/mkImports.nix args;
in
{
  # WSL-specific configuration
  wsl = {
    enable = true;
    defaultUser = username;
    startMenuLaunchers = true;
    
    # Enable native systemd support
    nativeSystemd = true;
    
    # WSL interoperability settings
    interop.register = true;
    interop.includePath = false;
  };

  imports = mkImports {
    inherit username;
    
    imports = [
      ./packages.nix
    ];
  };

  # System configuration
  system.stateVersion = "24.05";
  
  # Enable flakes and new nix command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;

  # User configuration
  users.users.${username} = {
    isNormalUser = true;
    home = "/home/${username}";
    shell = pkgs.fish;
    extraGroups = [ "wheel" "docker" "networkmanager" ];
  };

  # Enable sudo without password for wheel group (common in WSL)
  security.sudo.wheelNeedsPassword = false;

  # System packages and programs
  environment.systemPackages = with pkgs; [
    neovim
    tmux
    curl
    wget
    git
    unzip
    gcc
  ];

  # Shell configuration
  programs.fish.enable = true;
  environment.shells = with pkgs; [ fish zsh bash ];

  # Fonts (similar to your macOS config)
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # Enable Docker (useful in WSL)
  virtualisation.docker.enable = true;

  # Network configuration
  networking.hostName = "wsl-nixos";
  networking.networkmanager.enable = true;

  # Time zone (adjust as needed)
  time.timeZone = "Asia/Singapore";

  # Locale settings
  i18n.defaultLocale = "en_US.UTF-8";
}
