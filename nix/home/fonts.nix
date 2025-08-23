{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Font management tools
    fontconfig
  ];

  # Custom fonts installation - use macOS user fonts directory
  home.file = {
    "Library/Fonts/AtlassianMono-latin.ttf".source = ../../assets/fonts/AtlassianMono-latin.ttf;
    "Library/Fonts/AtlassianSans-latin.ttf".source = ../../assets/fonts/AtlassianSans-latin.ttf;
  };

  # Configure fontconfig to recognize the fonts
  home.file.".config/fontconfig/fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <dir>~/Library/Fonts</dir>
      
      <!-- Alias for Atlassian fonts -->
      <alias>
        <family>Atlassian Mono</family>
        <prefer>
          <family>AtlassianMono-latin</family>
        </prefer>
      </alias>
      
      <alias>
        <family>Atlassian Sans</family>
        <prefer>
          <family>AtlassianSans-latin</family>
        </prefer>
      </alias>
    </fontconfig>
  '';

  # Ensure fonts are refreshed after installation
  home.activation.refreshFonts = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -d "$HOME/Library/Fonts" ]; then
      run ${pkgs.fontconfig}/bin/fc-cache -f -v "$HOME/Library/Fonts" || true
    fi
  '';
}