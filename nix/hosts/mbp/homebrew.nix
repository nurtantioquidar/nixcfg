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
      "oven-sh/bun"
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
      "bun"
      "cloudflared"
    ];

    casks = [
      # "hammerspoon"
      "iina"
      "the-unarchiver"
      "slack"
      "pritunl"
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
      "claude-code"
      "gcloud-cli"
      "cursor"
      "ngrok"
      "jetbrains-toolbox"
      "rectangle"
      "caffeine"
      "whatsapp"
      "expressvpn"
      "visual-studio-code"
      "soundsource"
      "ghostty"
      "orbstack"
      "zed"
      "firefox"
    ];

    onActivation = {
      cleanup = "zap";
      autoUpdate = false;
    };
  };
}
