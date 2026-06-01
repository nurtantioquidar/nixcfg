{ pkgs, lib, ... }:

# Declarative Homebrew managed from the user-scoped Home Manager profile.
#
# The taps/brews/casks lists below are the single source of truth. A Brewfile
# is generated from them and applied by `brew bundle` during Home Manager
# activation, running as the owning user (nix-homebrew makes /opt/homebrew
# user-owned), so installs/upgrades/cleanup never need sudo.
#
# nix-homebrew (in nix/hosts/mbp/homebrew.nix) still owns one-time bootstrap:
# prefix ownership, Rosetta, and pinned tap checkouts.

lib.mkIf pkgs.stdenv.isDarwin (
  let
    taps = [
      "homebrew/cask"
      "manaflow-ai/cmux"
      "oven-sh/bun"
    ];

    brews = [
    ];

    casks = [
      "caffeine"
      "pritunl"
      "mullvad-vpn"
      "iina"
      "jetbrains-toolbox"
      "1password"
      "rectangle"
      "scroll-reverser"
      "the-unarchiver"
      "expressvpn"
      "soundsource"
      "orbstack"
    ];

    brewfile = pkgs.writeText "Brewfile" (
      lib.concatMapStrings (t: ''tap "${t}"'' + "\n") taps
      + lib.concatMapStrings (b: ''brew "${b}"'' + "\n") brews
      + lib.concatMapStrings (c: ''cask "${c}"'' + "\n") casks
    );
  in
  {
    # Resolve casks from the pinned local tap checkout instead of the JSON API.
    # See docs/setup-guide.md "Homebrew Cask API Fails During Rebuild".
    home.activation.brewBundle = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export PATH="/opt/homebrew/bin:$PATH"
      export HOMEBREW_NO_INSTALL_FROM_API=1
      export HOMEBREW_NO_AUTO_UPDATE=1
      $DRY_RUN_CMD brew bundle --file=${brewfile} --cleanup
    '';
  }
)
