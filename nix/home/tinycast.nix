{ pkgs, lib, ... }:

{
  config = lib.mkIf pkgs.stdenv.isDarwin {
    # Tinycast de-duplicates apps by bundle identifier, keeping the first match.
    # Prefer the user-owned Claude bundle over the IT-managed system copy.
    targets.darwin.defaults."com.tinycast.app".launcherSearchScopes = [
      "~/Applications/Claude.app"
      "/Applications"
      "/Applications/Utilities"
      "/System/Applications"
      "/System/Applications/Utilities"
      "/System/Library/CoreServices/Applications"
      "/System/Volumes/Preboot/Cryptexes/App/System/Applications"
      "/System/Library/CoreServices/Finder.app"
      "~/Applications"
    ];
  };
}
