{ pkgs, lib, ... }:

{
  home = {
    packages = [ pkgs.geist-font ];

    file.".config/zed/settings.json" = lib.mkIf pkgs.stdenv.isDarwin {
      text = builtins.toJSON {
        ui_font_family = "Geist";
        buffer_font_family = "Geist Mono";
        terminal.font_family = "Geist Mono";
      };
    };
  };
}
