#!/usr/bin/env bash
# Script to verify 1Password Git signing is set up correctly

set -u

tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/test-git-signing.XXXXXX")"
cleanup() {
    rm -rf "$tmpdir"
}
trap cleanup EXIT

echo "Verifying 1Password Git Signing Setup..."
echo ""

# Check 1Password SSH agent
echo "1. Checking 1Password SSH Agent..."
if [ -n "$SSH_AUTH_SOCK" ]; then
    echo "   OK: SSH_AUTH_SOCK is set: $SSH_AUTH_SOCK"
else
    echo "   MISSING: SSH_AUTH_SOCK is not set"
    echo "   Make sure 'Use the SSH agent' is enabled in 1Password Developer settings"
fi
echo ""

# Check for SSH keys
echo "2. Checking for SSH keys in agent..."
ssh-add -l 2>&1 | head -3
echo ""

# Check Git config
echo "3. Checking Git configuration..."
echo "   GPG format: $(git config --get gpg.format || echo 'NOT SET')"
echo "   GPG SSH program: $(git config --get gpg.ssh.program || echo 'NOT SET')"
echo "   Allowed signers: $(git config --get gpg.ssh.allowedSignersFile || echo 'NOT SET')"
echo "   Signing key: $(git config --get user.signingkey || echo 'NOT SET')"
echo "   Auto-sign commits: $(git config --get commit.gpgsign || echo 'NOT SET')"
echo ""

# Check local signature verification file
echo "4. Checking allowed signers file..."
allowed_signers_file="$(git config --get gpg.ssh.allowedSignersFile || true)"
if [ -n "$allowed_signers_file" ] && [ -f "$allowed_signers_file" ]; then
    echo "   OK: Found $allowed_signers_file"
else
    echo "   MISSING: gpg.ssh.allowedSignersFile is not configured or does not exist"
fi
echo ""

# Check if op-ssh-sign exists
echo "5. Checking 1Password SSH signing binary..."
if [ -f "/Applications/1Password.app/Contents/MacOS/op-ssh-sign" ]; then
    echo "   OK: Found /Applications/1Password.app/Contents/MacOS/op-ssh-sign"
else
    echo "   MISSING: /Applications/1Password.app/Contents/MacOS/op-ssh-sign"
fi
echo ""

# Test signing
echo "6. Testing commit signing..."
git -C "$tmpdir" init
printf 'test\n' > "$tmpdir/test.txt"
git -C "$tmpdir" add test.txt
if git -C "$tmpdir" commit -m "Test signed commit" 2>&1; then
    echo "   OK: Test commit created successfully"
    git -C "$tmpdir" log --show-signature -1
else
    echo "   FAILED: Could not create a signed commit"
fi

echo ""
echo "Verification complete."
