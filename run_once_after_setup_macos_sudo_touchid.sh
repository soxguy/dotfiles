#!/bin/sh
# Enable Touch ID for sudo on macOS via /etc/pam.d/sudo_local (survives OS updates)

[ "$(uname)" = "Darwin" ] || exit 0

# Already configured
grep -q "^auth.*pam_tid.so" /etc/pam.d/sudo_local 2>/dev/null && exit 0

echo "Enabling Touch ID for sudo..."

if [ ! -f /etc/pam.d/sudo_local ]; then
    sudo cp /etc/pam.d/sudo_local.template /etc/pam.d/sudo_local
fi

# Uncomment the pam_tid.so line
sudo sed -i '' 's/^#auth[[:space:]]*sufficient[[:space:]]*pam_tid.so/auth       sufficient     pam_tid.so/' /etc/pam.d/sudo_local

echo "Touch ID for sudo enabled."
