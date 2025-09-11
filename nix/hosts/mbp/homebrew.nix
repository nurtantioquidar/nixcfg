_:

{
  nix-homebrew = {
    enable = true;

    enableRosetta = true;

    user = "hades";

    autoMigrate = true;
  };

  homebrew = {
    enable = true;

    taps = [
    ];

    brews = [
      "act"
      "argocd"
      "colima"
      "docker"
      "docker-compose"
      "gnupg"
      "gpg2"
      "kubernetes-cli"
      "mas"
      "node"
      "oci-cli"
      "pinentry-mac"
      "slackdump"
      "gh"
      "woff2"
      "uv"
      "pnpm"
    ];

    casks = [
      "hammerspoon"
      "iina"
      "the-unarchiver"
      "slack"
      "pritunl"
      "wezterm"
      "visual-studio-code"
      "mullvad-vpn"
      "raycast"
      "spotify"
      "lens"
      "google-cloud-sdk"
      "1password"
      "zoom"
      "scroll-reverser"
      # "mos"
      "jordanbaird-ice"
      "claude"
      "firefox"
      "gcloud-cli"
      "cursor"
      "orion"
      "private-internet-access"
      "ngrok"
    ];

    # MAS apps managed by separate script (mas-install.sh) for better state management
    # Run: ./nix/hosts/mbp/mas-install.sh after darwin-rebuild
    # masApps = {
    #     "Magnet" = 441258766;
    #     "Wipr" = 1320666476;
    #     "Wipr 2" = 1662217862;
    #     "UpNote: notes, diary, journal" = 1398373917;
    #     "WhatsApp Messenger" = 310633997;
    # };
    onActivation = {
      cleanup = "zap";
      autoUpdate = false;
    };
  };
}
