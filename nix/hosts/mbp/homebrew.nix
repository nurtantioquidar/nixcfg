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
      "1password"
      "zoom"
      "scroll-reverser"
      # "mos"
      "jordanbaird-ice"
      "claude"
      "gcloud-cli"
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
      "obsidian"
      "codex"
    ];

    onActivation = {
      cleanup = "zap";
      autoUpdate = false;
    };
  };
}
