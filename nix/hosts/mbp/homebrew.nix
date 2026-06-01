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
      # "starship" # Using home-manager instead for better Nix integration
    ];

    casks = [
      # "hammerspoon"
      "caffeine"
      # "chatgpt"
      "pritunl"
      "mullvad-vpn"
      # "google-chrome"
      "iina"
      "jetbrains-toolbox"
      # "lens"
      "1password"
      # "obsidian"
      "rectangle"
      "scroll-reverser"
      # "slack"
      # "spotify"
      "the-unarchiver"
      # "visual-studio-code"
      # "zoom"
      # "whatsapp"
      "expressvpn"
      "soundsource"
      # "ghostty"
      "orbstack"
      # "zed"
      # "cmux"
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
