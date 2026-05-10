{ pkgs, lib, ... }:

let
  nodejs = pkgs.nodejs_24;
  npmPrefix = "$HOME/.local";

  globalPackages = [
    "@steipete/oracle"
  ];

  packageArgs = lib.concatStringsSep " " (map lib.escapeShellArg globalPackages);
in
{
  home.packages = [
    nodejs
  ];

  home.activation.installNodePackages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -euo pipefail

    export PATH="${nodejs}/bin:${pkgs.coreutils}/bin:$PATH"
    export npm_config_cache="$HOME/.cache/npm"
    export npm_config_prefix="${npmPrefix}"

    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${npmPrefix}" "$HOME/.cache/npm"

    missing_packages=()
    for package in ${packageArgs}; do
      if ! ${nodejs}/bin/npm list --global --depth=0 --prefix "${npmPrefix}" "$package" >/dev/null 2>&1; then
        missing_packages+=("$package")
      fi
    done

    if [ "''${#missing_packages[@]}" -gt 0 ]; then
      $DRY_RUN_CMD ${nodejs}/bin/npm install --global --no-audit --no-fund --prefix "${npmPrefix}" "''${missing_packages[@]}"
    fi
  '';
}
