#!/usr/bin/env bash

# Font installation automation script
set -e

echo "🔤 Installing custom fonts..."

# Create fonts directory if it doesn't exist
mkdir -p ~/.local/share/fonts

# Copy font files
echo "📋 Copying font files to ~/.local/share/fonts/"
cp assets/fonts/*.ttf ~/.local/share/fonts/

# Create fontconfig directory
mkdir -p ~/.config/fontconfig

# Create fontconfig configuration
echo "⚙️  Setting up fontconfig..."
cat > ~/.config/fontconfig/fonts.conf << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <dir>~/.local/share/fonts</dir>
  
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
EOF

# Refresh font cache
echo "🔄 Refreshing font cache..."
fc-cache -f

echo "✅ Font installation complete!"
echo ""
echo "Available fonts:"
fc-list | grep -i atlassian || echo "No Atlassian fonts found in cache yet - may need to restart applications"

echo ""
echo "To apply the full Nix configuration, run:"
echo "  sudo darwin-rebuild switch --flake .#styx"