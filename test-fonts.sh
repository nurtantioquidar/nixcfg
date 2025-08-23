#!/usr/bin/env bash

echo "🔍 Testing font installation..."

echo "📁 Fonts in ~/Library/Fonts:"
ls -la ~/Library/Fonts/ | grep -i atlassian

echo ""
echo "🔧 Fontconfig detection:"
fc-list | grep -i atlassian

echo ""
echo "🍎 macOS font validation:"
/usr/bin/atsutil fonts -list | grep -i atlassian || echo "Not found in atsutil fonts list"

echo ""
echo "📖 Trying to refresh Font Book database..."
echo "Note: This might require admin privileges for system-wide refresh"

# Try to refresh just user fonts
killall "Font Book" 2>/dev/null || true

echo ""
echo "✅ Manual test complete."
echo "Try opening Font Book now to see if fonts appear."
echo "If not, try restarting Font Book or logging out and back in."