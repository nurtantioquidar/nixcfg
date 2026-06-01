{ pkgs, lib, ... }:

let
  codexUpgrade = pkgs.writeShellScriptBin "codex-upgrade" ''
    set -eu

    export PATH="$HOME/.local/bin:${pkgs.curl}/bin:${pkgs.gawk}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.gnutar}/bin:${pkgs.gzip}/bin:${pkgs.coreutils}/bin:$PATH"

    ${pkgs.curl}/bin/curl -fsSL https://chatgpt.com/codex/install.sh \
      | CODEX_NON_INTERACTIVE=1 ${pkgs.bash}/bin/bash
  '';
in
{
  home.packages = [
    codexUpgrade
  ];

  home.activation.installCodexCli = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    case "$(${pkgs.coreutils}/bin/uname -s)" in
      Darwin|Linux)
        if [ ! -x "$HOME/.local/bin/codex" ]; then
          $DRY_RUN_CMD ${codexUpgrade}/bin/codex-upgrade
        fi
        ;;
    esac
  '';
}
