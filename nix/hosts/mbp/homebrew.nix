{ inputs, pkgs, lib, ... }:

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
      "suruseas/opossum/opossum"
    ];

    taps = {
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "manaflow-ai/homebrew-cmux" = inputs.homebrew-cmux;
      "abue-ammar/homebrew-tinycast" = inputs.homebrew-tinycast;
      "nikitabobko/homebrew-tap" = inputs.homebrew-aerospace;
      "suruseas/homebrew-opossum" = inputs.homebrew-opossum;
    };
  };

  # nix-homebrew creates the Taps parent as root on a fresh installation.
  # Home Manager needs a writable namespace for its unpinned crmne/tap.
  system.activationScripts.setup-homebrew.text = pkgs.lib.mkAfter ''
    if [ ! -d /opt/homebrew/Library/Taps ] || [ -L /opt/homebrew/Library/Taps ]; then
      echo "Expected an ordinary Homebrew Taps directory." >&2
      exit 1
    fi
    if [ -L /opt/homebrew/Library/Taps/crmne ]; then
      echo "Refusing to change a symlinked crmne tap namespace." >&2
      exit 1
    fi
    /usr/bin/install -d -o hades -g admin -m 0755 /opt/homebrew/Library/Taps/crmne
  '';

  # Keep personal-only app bundles user-owned without adding them to the
  # shared Home Manager cask list used by the company MBA and standalone profile.
  home-manager.users.hades.home.activation.installStyxHomebrewCasks =
    lib.hm.dag.entryAfter [ "installUserHomebrewCasks" ] ''
      if [ -x /opt/homebrew/bin/brew ]; then
        $DRY_RUN_CMD /usr/bin/env \
          HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications" \
          HOMEBREW_NO_AUTO_UPDATE=1 \
          HOMEBREW_NO_INSTALL_FROM_API=1 \
          /opt/homebrew/bin/brew bundle install --no-upgrade --file "${pkgs.writeText "styx-homebrew-Brewfile" ''
            cask "google-chrome"
          ''}"
      fi
    '';

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
