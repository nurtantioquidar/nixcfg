#!/usr/bin/env bash
set -e

echo "🧪 Testing manual font installation"

# Clean slate
echo "🧹 Cleaning up any existing font files"
rm -f ~/Library/Fonts/Atlassian*.ttf
rm -f ~/.local/share/fonts/Atlassian*.ttf
rm -rf ~/.cache/fontconfig

# Copy one font to Downloads for testing
echo "📋 Copying test font to Downloads"
cp assets/fonts/AtlassianSans-latin.ttf ~/Downloads/TestAtlassianSans.ttf

echo "🔍 Double-click ~/Downloads/TestAtlassianSans.ttf to install it"
echo "📖 Then check Font Book to see if it appears"
echo ""
echo "If it works manually, we know the font file is good."
echo "If it doesn't work manually, there's an issue with the font itself."

# Open the font file for installation
open ~/Downloads/TestAtlassianSans.ttf

echo ""
echo "✅ Test font opened. Check Font Book now."
echo "Press Enter when you've tested the manual installation..."
read -r

# Check if it was installed
if ls ~/Library/Fonts/ | grep -i atlassian > /dev/null 2>&1; then
    echo "✅ Font was manually installed successfully!"
    echo "📁 Found in ~/Library/Fonts/:"
    ls -la ~/Library/Fonts/ | grep -i atlassian
else
    echo "❌ Manual installation failed - font not found in ~/Library/Fonts/"
fi

# Cleanup
rm -f ~/Downloads/TestAtlassianSans.ttf