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
      "sdkman/tap"
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
      "git"
      "gh"
      "woff2"
      "uv"
      "pnpm"
      "sdkman-cli"
      "tree"
      "pipx"
      # "starship" # Using home-manager instead for better Nix integration
    ];

    casks = [
      # "hammerspoon"
      "iina"
      "the-unarchiver"
      "slack"
      "pritunl"
      # "visual-studio-code"
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
      "claude-code"
      "gcloud-cli"
      "cursor"
      "ngrok"
      "jetbrains-toolbox"
      "rectangle"
      "caffeine"
      "whatsapp"
    ];

    onActivation = {
      cleanup = "zap";
      autoUpdate = false;
    };
  };
}
