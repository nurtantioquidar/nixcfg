#!/usr/bin/env bash

# Smart MAS installer - only installs if not already present
# Usage: ./mas-install.sh

set -e

# Define MAS apps with their IDs and names
declare -A MAS_APPS=(
    ["1320666476"]="Wipr"
    ["1662217862"]="Wipr 2"
    ["310633997"]="WhatsApp Messenger"
)

echo "🔍 Checking MAS apps installation status..."

# Get list of installed apps
INSTALLED_APPS=$(mas list | awk '{print $1}')

for app_id in "${!MAS_APPS[@]}"; do
    app_name="${MAS_APPS[$app_id]}"
    
    if echo "$INSTALLED_APPS" | grep -q "^$app_id$"; then
        echo "✅ $app_name ($app_id) - Already installed"
    else
        echo "📦 Installing $app_name ($app_id)..."
        mas install "$app_id"
        echo "✅ $app_name installed successfully"
    fi
done

echo "🎉 MAS apps check complete!"
