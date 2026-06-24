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
      "pritunl"
      "mullvad-vpn"
      "1password"
      "expressvpn"
    ];

    onActivation = {
      cleanup = "none";
      autoUpdate = true;
      extraEnv = {
        HOMEBREW_NO_INSTALL_FROM_API = "1";
      };
    };
  };
}
