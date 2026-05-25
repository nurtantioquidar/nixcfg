{ inputs, ... }:

{
  nix-homebrew = {
    enable = true;

    enableRosetta = true;

    user = "hades";

    autoMigrate = true;

    taps = {
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "manaflow-ai/homebrew-cmux" = inputs.homebrew-cmux;
    };
  };

  homebrew = {
    enable = true;

    taps = [
      "homebrew/cask"
      "manaflow-ai/cmux"
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
      # Required by installed Homebrew casks; keep them listed so cleanup can zap
      # unmanaged packages without trying to remove live cask dependencies.
      "python@3.13"
      "ripgrep"
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
      # "raycast"
      "spotify"
      "lens"
      "1password"
      "zoom"
      "scroll-reverser"
      # "mos"
      # "jordanbaird-ice"
      "claude"
      "ngrok"
      "jetbrains-toolbox"
      "rectangle"
      "caffeine"
      # WhatsApp's vendor download endpoint has returned HTTP 500 during activation.
      # Keep it out of nix-darwin activation so rebuilds are not blocked by that cask.
      # "whatsapp"
      "expressvpn"
      "visual-studio-code"
      "soundsource"
      "ghostty"
      "orbstack"
      # "zed"
      # "firefox"
      "obsidian"
      "codex"
      "brave-browser"
      "chatgpt"
      "cmux"
    ];

    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      extraEnv = {
        HOMEBREW_NO_INSTALL_FROM_API = "1";
      };
    };
  };
}
