#!/usr/bin/env bash

echo "🔬 Testing different font installation methods"

# Method 1: Try system fontdir
echo ""
echo "📁 Method 1: Installing to /System/Library/Fonts (requires sudo)"
echo "This is where system fonts live on macOS"

# Method 2: Try Library/Fonts with proper registration  
echo ""
echo "📁 Method 2: Installing to ~/Library/Fonts with atsutil registration"
sudo rm -f ~/Library/Fonts/AtlassianSans-latin.ttf 2>/dev/null || true
cp assets/fonts/AtlassianSans-latin.ttf ~/Library/Fonts/
echo "Font copied. Trying to force font database refresh..."

# Try to refresh the font database 
sudo atsutil databases -remove 2>/dev/null || echo "Could not remove font database (expected)"
atsutil databases -remove 2>/dev/null || echo "Could not remove user font database (expected)" 

echo ""
echo "🔍 Checking if font appears in system now:"
sleep 2
nix-shell -p fontconfig --run "fc-list | grep -i atlassian" || echo "Not found in fontconfig"

echo ""
echo "📖 Check Font Book now to see if AtlassianSans appears"
echo "If it appears, we know the method works and can automate it."