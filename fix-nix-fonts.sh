#!/usr/bin/env bash

echo "Fixing Atlassian fonts in /Library/Fonts/Nix Fonts/"

# Create a flat directory structure for better macOS recognition
sudo mkdir -p "/Library/Fonts/Nix Fonts/Atlassian"

# Find the current atlassian fonts in the nix store structure
ATLASSIAN_DIR=$(find "/Library/Fonts/Nix Fonts/" -name "*atlassian-fonts*" -type d | head -1)

if [ -n "$ATLASSIAN_DIR" ]; then
    echo "Found Atlassian fonts at: $ATLASSIAN_DIR"
    
    # Copy fonts to a flatter structure that macOS can find more easily
    echo "Copying fonts to flat structure..."
    sudo cp -v "$ATLASSIAN_DIR/share/fonts/truetype/"*.ttf "/Library/Fonts/Nix Fonts/"
    
    # Also copy to dedicated Atlassian folder
    sudo cp -v "$ATLASSIAN_DIR/share/fonts/truetype/"*.ttf "/Library/Fonts/Nix Fonts/Atlassian/"
    
    # Set proper permissions
    sudo chmod 644 "/Library/Fonts/Nix Fonts/"Atlassian*.ttf
    sudo chmod 644 "/Library/Fonts/Nix Fonts/Atlassian/"*.ttf
    
    echo "✓ Fonts copied successfully"
else
    echo "✗ Could not find Atlassian fonts in Nix Fonts directory"
    echo "Available font packages:"
    ls -la "/Library/Fonts/Nix Fonts/"
    exit 1
fi

# Clear font cache
echo "Clearing font cache..."
sudo atsutil databases -remove 2>/dev/null || true

echo "✓ Font installation fixed!"
echo ""
echo "The fonts should now be available as:"
echo "  - AtlassianMono-latin"
echo "  - AtlassianSans-latin" 
echo ""
echo "Please restart any open applications to see the fonts."