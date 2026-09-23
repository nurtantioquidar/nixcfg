{ pkgs, lib, ... }:

{
  home.file.".config/ghostty/config" = lib.mkIf pkgs.stdenv.isDarwin {
    text = ''
      # aesthetics
      theme = dark:Catppuccin Mocha,light:Catppuccin Latte
      background-opacity = 0.85
      background-blur = 16
      # background = #000000
      window-padding-x = 8
      window-padding-y = 8
      window-decoration = true

      # typography
      font-family = Berkeley Mono
      font-family-bold = Berkeley Mono
      font-family-italic = Berkeley Mono
      font-family-bold-italic = Berkeley Mono
      font-style-bold = Bold
      font-style-italic = Oblique
      font-style-bold-italic = Bold Oblique
      font-size = 12
      font-thicken = true
      font-thicken-strength = 1
      adjust-cell-height = 1

      # cursor and shell
      cursor-style = block
      cursor-style-blink = true
      shell-integration = zsh

      # macOS input
      macos-option-as-alt = left

      # Let the shell keep Option+Arrow word navigation.
      keybind = alt+left=unbind
      keybind = alt+right=unbind
    '';
  };
}
