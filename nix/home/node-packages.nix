{ pkgs, lib, config, ... }:

let
  nodejs = pkgs.nodejs_24;
  npmPrefix = "${config.home.homeDirectory}/.local";
  npmCache = "${config.home.homeDirectory}/.cache/npm";

  globalPackages = [
    "oh-my-codex"
    "opencode-ai"
  ];

  packageArgs = lib.concatStringsSep " " (map lib.escapeShellArg globalPackages);
  latestPackageArgs = lib.concatStringsSep " " (map (package: lib.escapeShellArg "${package}@latest") globalPackages);

  nodePackagesUpgrade = pkgs.writeShellScriptBin "node-packages-upgrade" ''
    set -eu

    export PATH="${nodejs}/bin:${pkgs.coreutils}/bin:$PATH"
    export npm_config_cache="${npmCache}"
    export npm_config_prefix="${npmPrefix}"

    ${pkgs.coreutils}/bin/mkdir -p "${npmPrefix}" "${npmCache}"
    exec ${nodejs}/bin/npm install --global --no-audit --no-fund --prefix "${npmPrefix}" ${latestPackageArgs}
  '';
in
{
  home.packages = [
    nodejs
    nodePackagesUpgrade
  ];

  home.file.".npmrc".text = ''
    prefix=${npmPrefix}
    cache=${npmCache}
  '';

  # Keep global npm installs user-writable. Both .npmrc and the activation
  # environment point npm at ~/.local so manual `npm install --global` and this
  # managed installer do not try to write into the immutable Nix store.
  home.activation.installNodePackages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -euo pipefail

    export PATH="${nodejs}/bin:${pkgs.coreutils}/bin:$PATH"
    export npm_config_cache="${npmCache}"
    export npm_config_prefix="${npmPrefix}"

    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${npmPrefix}" "${npmCache}"

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
