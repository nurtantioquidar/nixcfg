#!/usr/bin/env bash
set -e

echo "🔤 Manual Font Installation Test"

# Remove existing fonts first
rm -f ~/Library/Fonts/AtlassianMono-latin.ttf
rm -f ~/Library/Fonts/AtlassianSans-latin.ttf

echo "📋 Copying fonts to ~/Library/Fonts/"
cp assets/fonts/AtlassianMono-latin.ttf ~/Library/Fonts/
cp assets/fonts/AtlassianSans-latin.ttf ~/Library/Fonts/

echo "⚙️ Setting permissions"
chmod 644 ~/Library/Fonts/Atlassian*.ttf

echo "🔄 Refreshing font cache with fontconfig"
fc-cache -f -v ~/Library/Fonts/

echo "🍎 Opening fonts in Font Book to trigger registration"
open -a "Font Book" ~/Library/Fonts/AtlassianMono-latin.ttf
open -a "Font Book" ~/Library/Fonts/AtlassianSans-latin.ttf

echo "✅ Manual installation complete!"
echo "Check Font Book now - the fonts should appear."
echo ""
echo "If they appear, the issue is with our Nix activation script."
echo "If they don't appear, the issue is deeper in the macOS font system."