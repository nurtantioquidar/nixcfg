#!/usr/bin/env bash

echo "Testing Atlassian font installation..."

echo "1. Checking if fonts are in ~/Library/Fonts:"
ls -la ~/Library/Fonts/Atlassian* 2>/dev/null || echo "  No fonts found in ~/Library/Fonts"

echo ""
echo "2. Checking if fonts are in nix store:"
find /nix/store -name "*atlassian*" -type d 2>/dev/null | head -5

echo ""
echo "3. Checking current nix-darwin system fonts:"
if [ -d "/run/current-system/sw/share/fonts" ]; then
    find /run/current-system/sw/share/fonts -name "*tlassian*" 2>/dev/null || echo "  No Atlassian fonts found in system fonts"
else
    echo "  System fonts directory not found (may need darwin-rebuild)"
fi

echo ""
echo "4. Testing font recognition with available tools:"
if command -v fc-list >/dev/null 2>&1; then
    echo "  fontconfig available - checking font list:"
    fc-list | grep -i atlassian || echo "    No Atlassian fonts found by fontconfig"
else
    echo "  fontconfig not available in current environment"
fi

echo ""
echo "5. Checking if fonts can be opened:"
for font in ~/Library/Fonts/Atlassian*.ttf; do
    if [ -f "$font" ]; then
        echo "  Testing: $(basename "$font")"
        if file "$font" | grep -q "TrueType"; then
            echo "    ✓ Valid TrueType font"
        else
            echo "    ✗ Invalid font file"
        fi
    fi
done

echo ""
echo "=== Font Installation Status ==="
echo "The fonts should be available to applications now."
echo "If fonts still don't appear, try:"
echo "1. Restart your application"
echo "2. Run: sudo darwin-rebuild switch --flake .#styx" 
echo "3. Clear font cache: atsutil databases -remove (requires sudo)"
echo "4. Restart Font Book app"