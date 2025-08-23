{ pkgs, lib, ... }:

{
  # Install fonts using multiple methods to ensure they work
  home.activation.installCustomFonts = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "🔤 Installing custom fonts..."
    
    # Ensure directories exist
    mkdir -p "$HOME/Library/Fonts"
    mkdir -p "$HOME/.local/share/fonts"
    
    # Method 1: Install to ~/Library/Fonts (macOS standard location)
    echo "📋 Installing fonts to ~/Library/Fonts"
    cp -f "${../../assets/fonts/AtlassianMono-latin.ttf}" "$HOME/Library/Fonts/AtlassianMono-latin.ttf" || true
    cp -f "${../../assets/fonts/AtlassianSans-latin.ttf}" "$HOME/Library/Fonts/AtlassianSans-latin.ttf" || true
    
    # Method 2: Also install to ~/.local/share/fonts for fontconfig compatibility
    echo "📋 Installing fonts to ~/.local/share/fonts"
    cp -f "${../../assets/fonts/AtlassianMono-latin.ttf}" "$HOME/.local/share/fonts/AtlassianMono-latin.ttf" || true
    cp -f "${../../assets/fonts/AtlassianSans-latin.ttf}" "$HOME/.local/share/fonts/AtlassianSans-latin.ttf" || true
    
    # Set proper permissions
    chmod 644 "$HOME/Library/Fonts"/Atlassian*.ttf || true
    chmod 644 "$HOME/.local/share/fonts"/Atlassian*.ttf || true
    
    # Clear fontconfig cache and rebuild
    rm -rf "$HOME/.cache/fontconfig" || true
    
    # Refresh fontconfig cache
    if command -v fc-cache >/dev/null 2>&1; then
        run fc-cache -f -v "$HOME/Library/Fonts" "$HOME/.local/share/fonts" || true
    else
        run ${pkgs.fontconfig}/bin/fc-cache -f -v "$HOME/Library/Fonts" "$HOME/.local/share/fonts" || true
    fi
    
    # Try to refresh macOS font database (may require user interaction)
    echo "🔄 Attempting to refresh macOS font database..."
    /usr/bin/atsutil databases -removeUser || true
    
    echo "✅ Font installation completed!"
    echo ""
    echo "📝 To ensure fonts appear in Font Book:"
    echo "   1. Open Font Book application"
    echo "   2. If fonts don't appear, restart Font Book"
    echo "   3. Or double-click the font files in ~/Library/Fonts to register them"
    echo ""
    echo "🔍 Fonts should be available in applications immediately as:"
    echo "   - Atlassian Mono"
    echo "   - Atlassian Sans"
  '';
  
  # Create fontconfig configuration for better font discovery
  home.file.".config/fontconfig/fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <!-- Add font directories -->
      <dir>~/Library/Fonts</dir>
      <dir>~/.local/share/fonts</dir>
      
      <!-- Aliases for easier font selection -->
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
      
      <!-- Fallbacks -->
      <alias>
        <family>monospace</family>
        <prefer>
          <family>Atlassian Mono</family>
        </prefer>
      </alias>
      
      <alias>
        <family>sans-serif</family>
        <prefer>
          <family>Atlassian Sans</family>
        </prefer>
      </alias>
    </fontconfig>
  '';
}