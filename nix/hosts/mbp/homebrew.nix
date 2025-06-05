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

    brews = [
      "mas"
      "oci-cli"
      "kubernetes-cli"
      "gpg2"
      "gnupg"
      "pinentry-mac"
      "argocd"
      "slackdump"
    ];

    casks = [
      "hammerspoon"
      "iina"
      "the-unarchiver"
      "slack"
      "pritunl"
      "wezterm"
      "visual-studio-code"
      "mullvadvpn"
      "raycast"
      "spotify"
      "lens"
      "google-cloud-sdk"
      "1password"
      "zoom"
      "scroll-reverser"
      "mos"
      "postman"
    ];

    masApps = {
        "Magnet" = 441258766;
        "Wipr" = 1320666476;
        "Wipr 2" = 1662217862;
        "UpNote: notes, diary, journal" = 1398373917;
        "WhatsApp Messenger" = 310633997;
    };
    onActivation.cleanup = "zap";
  };
}
