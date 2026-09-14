{ pkgs, ... }:

let
  herdrWithTerminalCleanup = pkgs.writeShellScriptBin "herdr" ''
    cleanup_mouse_reporting() {
      if [[ -t 1 ]]; then
        # Herdr clears these before leaving the alternate screen. Some
        # terminals restore the saved modes afterwards, so clear them again.
        printf '\033[?1006l\033[?1016l\033[?1015l\033[?1005l\033[?1003l\033[?1002l\033[?1000l'
      fi
    }

    trap cleanup_mouse_reporting EXIT
    ${pkgs.herdr}/bin/herdr "$@"
    exit $?
  '';
in
{
  home.packages = [
    herdrWithTerminalCleanup
  ];

  xdg.configFile."herdr/config.toml" = {
    force = true;
    text = ''
      onboarding = false

      [ui]
      show_agent_labels_on_pane_borders = true
      mouse_capture = true

      [theme]
      name = "rose-pine"
      auto_switch = false
    '';
  };
}
