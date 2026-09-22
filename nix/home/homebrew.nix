{ pkgs, lib, ... }:

let
  # User-owned app-bundle casks installed into $HOME/Applications by the
  # Home Manager activation below. Treat membership changes as state-changing:
  # removing an entry that was previously written to managed-casks can uninstall
  # that cask during activation unless it remains listed in systemCasks or is
  # moved through an explicit user/admin flow.
  userCasks = [
    "abue-ammar/tinycast/tinycast"
    "caffeine"
    "claude"
    "ghostty"
    "iina"
    "jetbrains-toolbox"
    "manaflow-ai/cmux/cmux"
    "nikitabobko/tap/aerospace"
    "obsidian"
    "orbstack"
    "rectangle"
    "scroll-reverser"
    "soundsource"
    "spotify"
    "the-unarchiver"
  ];

  # These were briefly user-managed during the Homebrew split, but they are
  # installer/pkg casks that do not honor the user appdir cleanly.
  systemCasks = [
    "expressvpn"
    "mullvad-vpn"
  ];

  brewfile = pkgs.writeText "user-homebrew-Brewfile" ''
    tap "homebrew/cask"
    tap "abue-ammar/tinycast"
    tap "manaflow-ai/cmux"
    tap "nikitabobko/tap"

    ${lib.concatMapStringsSep "\n" (cask: ''cask "${cask}"'') userCasks}
  '';

  userCasksList = pkgs.writeText "user-homebrew-casks" ''
    ${lib.concatStringsSep "\n" userCasks}
  '';

  systemCasksList = pkgs.writeText "system-homebrew-casks" ''
    ${lib.concatStringsSep "\n" systemCasks}
  '';
in
{
  config = lib.mkIf pkgs.stdenv.isDarwin {
    home = {
      file.".config/homebrew/Brewfile".source = brewfile;

      sessionVariables.HOMEBREW_BUNDLE_FILE_GLOBAL = "$HOME/.config/homebrew/Brewfile";

      activation.installUserHomebrewCasks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ -x /opt/homebrew/bin/brew ]; then
          state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/home-manager-homebrew"
          managed_casks="$state_dir/managed-casks"
          # Scope the custom app directory to this activation. Exporting it as a
          # session variable also redirects Darwin-owned system casks here.
          export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"
          export HOMEBREW_NO_AUTO_UPDATE=1

          # Trust only the exact third-party casks Home Manager installs, not
          # either full tap.
          $DRY_RUN_CMD /opt/homebrew/bin/brew trust --cask abue-ammar/tinycast/tinycast
          $DRY_RUN_CMD /opt/homebrew/bin/brew trust --cask manaflow-ai/cmux/cmux
          $DRY_RUN_CMD /opt/homebrew/bin/brew trust --cask nikitabobko/tap/aerospace

          if [ -f "$managed_casks" ]; then
            while IFS= read -r cask; do
              # Prune only casks this Home Manager module previously recorded as
              # managed, and never prune entries that are now classified as
              # system/admin casks.
              if [ -n "$cask" ] && ! ${pkgs.gnugrep}/bin/grep -qxF "$cask" "${userCasksList}" && ! ${pkgs.gnugrep}/bin/grep -qxF "$cask" "${systemCasksList}"; then
                if /opt/homebrew/bin/brew list --cask "$cask" >/dev/null 2>&1; then
                  $DRY_RUN_CMD /opt/homebrew/bin/brew uninstall --cask "$cask"
                fi
              fi
            done < "$managed_casks"
          fi

          $DRY_RUN_CMD /opt/homebrew/bin/brew bundle install --file "${brewfile}" --no-upgrade
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$state_dir"
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0644 "${userCasksList}" "$managed_casks"
        fi
      '';
    };
  };
}
