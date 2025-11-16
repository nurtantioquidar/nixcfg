#!/usr/bin/env bash
# Script to verify 1Password Git signing is set up correctly

echo "🔍 Verifying 1Password Git Signing Setup..."
echo ""

# Check 1Password SSH agent
echo "1️⃣  Checking 1Password SSH Agent..."
if [ -n "$SSH_AUTH_SOCK" ]; then
    echo "   ✅ SSH_AUTH_SOCK is set: $SSH_AUTH_SOCK"
else
    echo "   ❌ SSH_AUTH_SOCK is not set"
    echo "   💡 Make sure 'Use the SSH agent' is enabled in 1Password Developer settings"
fi
echo ""

# Check for SSH keys
echo "2️⃣  Checking for SSH keys in agent..."
ssh-add -l 2>&1 | head -3
echo ""

# Check Git config
echo "3️⃣  Checking Git configuration..."
echo "   GPG format: $(git config --get gpg.format || echo 'NOT SET')"
echo "   GPG SSH program: $(git config --get gpg.ssh.program || echo 'NOT SET')"
echo "   Signing key: $(git config --get user.signingkey || echo 'NOT SET')"
echo "   Auto-sign commits: $(git config --get commit.gpgsign || echo 'NOT SET')"
echo ""

# Check if op-ssh-sign exists
echo "4️⃣  Checking 1Password SSH signing binary..."
if [ -f "/Applications/1Password.app/Contents/MacOS/op-ssh-sign" ]; then
    echo "   ✅ Found: /Applications/1Password.app/Contents/MacOS/op-ssh-sign"
else
    echo "   ❌ NOT FOUND: /Applications/1Password.app/Contents/MacOS/op-ssh-sign"
fi
echo ""

# Test signing
echo "5️⃣  Testing commit signing..."
cd /tmp
rm -rf test-git-signing 2>/dev/null
git init test-git-signing
cd test-git-signing
git config user.name "Test User"
git config user.email "test@example.com"
echo "test" > test.txt
git add test.txt
if git commit -m "Test signed commit" 2>&1; then
    echo "   ✅ Test commit created successfully"
    git log --show-signature -1
else
    echo "   ❌ Failed to create signed commit"
fi
cd /tmp
rm -rf test-git-signing

echo ""
echo "✨ Verification complete!"
