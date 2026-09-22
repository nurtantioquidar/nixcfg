{ inputs, ... }:

{
  nix-homebrew = {
    enable = true;

    enableRosetta = true;

    user = "hades";

    autoMigrate = true;

    trust.casks = [
      "abue-ammar/tinycast/tinycast"
      "manaflow-ai/cmux/cmux"
      "nikitabobko/tap/aerospace"
    ];

    taps = {
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "manaflow-ai/homebrew-cmux" = inputs.homebrew-cmux;
      "abue-ammar/homebrew-tinycast" = inputs.homebrew-tinycast;
    };
  };

  homebrew = {
    enable = true;

    taps = [
      "homebrew/cask"
      "manaflow-ai/cmux"
    ];

    brews = [
      # "starship" # Using home-manager instead for better Nix integration
    ];

    casks = [
      "pritunl"
      "mullvad-vpn"
      "1password"
      # ExpressVPN is preinstalled and managed by the company on this MBA.
      # Do not let Homebrew replace its app or privileged daemon.
      "cloudflare-warp"
    ];

    onActivation = {
      # Keep Darwin activation from pruning user-managed Homebrew casks. The
      # user-level Home Manager module owns ordinary app-bundle casks.
      cleanup = "none";
      autoUpdate = true;
      extraEnv = {
        HOMEBREW_NO_INSTALL_FROM_API = "1";
      };
    };
  };
}
