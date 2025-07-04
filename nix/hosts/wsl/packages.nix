{ pkgs, ... }:

{
  # System packages that replace your Homebrew brews
  environment.systemPackages = with pkgs; [
    # Development tools (from your Homebrew brews)
    nodejs
    kubernetes
    kubectl
    argocd
    gnupg
    pinentry-curses  # Linux equivalent of pinentry-mac
    
    # Cloud tools
    google-cloud-sdk
    oci-cli
    
    # System utilities
    htop
    jq
    ripgrep
    curl
    wget
    unzip
    tree
    fd
    bat
    eza  # Modern ls replacement
    
    # Development essentials
    git
    tmux
    neovim
    gcc
    python3
    rustc
    cargo
    
    # Network tools
    nmap
    netcat
    openssh
    
    # Archive tools
    p7zip
    unrar
    
    # Text processing
    sed
    awk
    grep
    
    # Process management
    ps
    killall
    
    # File system tools
    rsync
    rclone
  ];

  # Programs with special configuration
  programs = {
    # Git configuration
    git = {
      enable = true;
      package = pkgs.git;
    };
    
    # SSH configuration
    ssh.startAgent = true;
    
    # GPG configuration
    gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-curses;
    };
  };

  # Services that might be useful in WSL
  services = {
    # SSH daemon (if you want to SSH into WSL)
    openssh = {
      enable = false;  # Set to true if needed
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
  };
}
