{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Font management tools
    fontconfig
  ];

  # Fonts will be installed via home activation script below

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

  # Copy fonts and register them with macOS properly
  home.activation.installFonts = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "Installing custom fonts to ~/Library/Fonts..."
    
    # Ensure fonts directory exists
    mkdir -p "$HOME/Library/Fonts"
    
    # Copy fonts directly (not symlink) for better macOS compatibility
    cp -f "${../../assets/fonts/AtlassianMono-latin.ttf}" "$HOME/Library/Fonts/AtlassianMono-latin.ttf" || true
    cp -f "${../../assets/fonts/AtlassianSans-latin.ttf}" "$HOME/Library/Fonts/AtlassianSans-latin.ttf" || true
    
    # Set proper permissions
    chmod 644 "$HOME/Library/Fonts"/Atlassian*.ttf || true
    
    # Refresh fontconfig cache
    run ${pkgs.fontconfig}/bin/fc-cache -f -v "$HOME/Library/Fonts" || true
    
    echo "Custom fonts installed successfully."
    echo "Note: You may need to restart Font Book to see the new fonts."
    echo "The fonts are available to applications immediately."
  '';
}