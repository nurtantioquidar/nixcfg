{ pkgs, ... }:

{
  home.packages = [
    pkgs.herdr
  ];

  xdg.configFile."herdr/config.toml" = {
    force = true;
    text = ''
      onboarding = false

      [ui]
      show_agent_labels_on_pane_borders = true
      # Herdr's mouse-capture mode can survive detach and send SGR mouse
      # reports into the parent shell. Leave mouse handling to the terminal.
      mouse_capture = false

      [theme]
      name = "rose-pine"
      auto_switch = false
    '';
  };
}
