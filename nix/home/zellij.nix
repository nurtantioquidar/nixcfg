{ pkgs, ... }:
let
  zellijNoGhosttyQueries = (pkgs.writeShellScriptBin "zellij" ''
    ghostty_outer_tty=false

    if [ "''${TERM:-}" = "xterm-ghostty" ]; then
      ghostty_outer_tty=true
      export ZELLIJ_ORIGINAL_TERM="$TERM"
      export TERM=xterm-256color
    fi

    case "''${TMPDIR:-}" in
      */nix-shell.*|*/nix-shell.*/*)
        export ZELLIJ_ORIGINAL_TMPDIR="$TMPDIR"
        tmp_parent="''${TMPDIR%%/nix-shell.*}"
        if [ -n "$tmp_parent" ] && [ -d "$tmp_parent" ]; then
          export TMPDIR="$tmp_parent/"
        elif [ -d /private/tmp ]; then
          export TMPDIR=/private/tmp/
        fi
        ;;
    esac

    ${pkgs.zellij}/bin/zellij "$@"
    status=$?

    if [ "$ghostty_outer_tty" = true ] && ${pkgs.coreutils}/bin/tty -s && old_stty="$(${pkgs.coreutils}/bin/stty -g < /dev/tty 2>/dev/null)"; then
      # Ghostty can answer Zellij's color-scheme query after Zellij exits.
      # Drain that pending DSR response so zsh does not read it as input.
      printf '\033[?2031l' > /dev/tty 2>/dev/null || true
      ${pkgs.coreutils}/bin/sleep 0.05
      ${pkgs.coreutils}/bin/stty -icanon -echo min 0 time 0 < /dev/tty 2>/dev/null || true
      while IFS= read -r -s -n 1 -t 0.02 _ < /dev/tty 2>/dev/null; do
        :
      done
      ${pkgs.coreutils}/bin/stty "$old_stty" < /dev/tty 2>/dev/null || true
    fi

    exit "$status"
  '') // {
    version = pkgs.zellij.version;
  };
in
{
  home.file.".config/zellij/config.kdl" = {
    text = ''
      theme "default"
      osc8_hyperlinks false
      support_kitty_keyboard_protocol false
    '';
    force = true;
  };

  programs.zellij = {
    enable = true;
    package = zellijNoGhosttyQueries;
  };
}
