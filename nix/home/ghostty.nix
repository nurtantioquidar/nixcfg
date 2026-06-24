{ pkgs, lib, ... }:

{
  home.file.".config/ghostty/config" = lib.mkIf pkgs.stdenv.isDarwin {
    text = ''
      # aesthetics
      background-opacity = 0.85
      background-blur = 16
      background = #000000
      macos-titlebar-style = hidden

      # typography
      font-family = "Berkeley Mono"
      font-size = 12
      font-thicken = true
      font-thicken-strength = 1
      adjust-cell-height = 1

      # macOS input
      macos-option-as-alt = left

      # Let the shell keep Option+Arrow word navigation.
      keybind = alt+left=unbind
      keybind = alt+right=unbind
    '';
  };
}
