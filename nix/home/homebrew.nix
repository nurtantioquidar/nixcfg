{ pkgs, lib, ... }:

let
  userCasks = [
    "caffeine"
    "iina"
    "jetbrains-toolbox"
    "rectangle"
    "scroll-reverser"
    "the-unarchiver"
  ];

  brewfile = pkgs.writeText "user-homebrew-Brewfile" ''
    tap "homebrew/cask"

    ${lib.concatMapStringsSep "\n" (cask: ''cask "${cask}"'') userCasks}
  '';

  userCasksList = pkgs.writeText "user-homebrew-casks" ''
    ${lib.concatStringsSep "\n" userCasks}
  '';
in
{
  config = lib.mkIf pkgs.stdenv.isDarwin {
    home.file.".config/homebrew/Brewfile".source = brewfile;

    home.sessionVariables = {
      HOMEBREW_BUNDLE_FILE_GLOBAL = "$HOME/.config/homebrew/Brewfile";
      HOMEBREW_CASK_OPTS = "--appdir=/Users/hades/Applications";
    };

    home.activation.installUserHomebrewCasks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -x /opt/homebrew/bin/brew ]; then
        state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/home-manager-homebrew"
        managed_casks="$state_dir/managed-casks"
        export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"
        export HOMEBREW_NO_AUTO_UPDATE=1

        if [ -f "$managed_casks" ]; then
          while IFS= read -r cask; do
            if [ -n "$cask" ] && ! ${pkgs.gnugrep}/bin/grep -qxF "$cask" "${userCasksList}"; then
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
}
