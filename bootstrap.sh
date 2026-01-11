#!/bin/bash
set -e

# Set up PATH immediately so all tools work throughout the script
export PATH="$HOME/.local/bin:/snap/bin:$PATH"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# GitHub username for dotfiles repo
GITHUB_USER="${GITHUB_USER:-soxguy}"

info "Starting minimal bootstrap process..."

# Ensure ~/.local/bin exists
mkdir -p ~/.local/bin

# Update package lists
info "Updating package lists..."
sudo apt update

# Install absolute essentials needed for Ansible and bootstrap
info "Installing essential packages for Ansible and bootstrap..."
sudo apt install -y \
    git \
    python3 \
    python3-pip \
    python3-apt \
    curl \
    unzip \
    jq

# Install Ansible
if ! command -v ansible-pull &> /dev/null; then
    info "Installing Ansible..."
    sudo apt install -y software-properties-common
    sudo add-apt-repository -y ppa:ansible/ansible
    sudo apt update
    sudo apt install -y ansible
else
    info "Ansible already installed"
fi

# Install chezmoi
if ! command -v chezmoi &> /dev/null; then
    info "Installing chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
else
    info "chezmoi already installed"
fi

# Install Bitwarden CLI (needed before chezmoi init for templates)
if ! command -v bw &> /dev/null; then
    info "Installing Bitwarden CLI..."
    curl -sL "https://vault.bitwarden.com/download/?app=cli&platform=linux" -o /tmp/bw.zip
    unzip -o /tmp/bw.zip -d ~/.local/bin
    chmod +x ~/.local/bin/bw
    rm /tmp/bw.zip
else
    info "Bitwarden CLI already installed"
fi

# Bitwarden login and unlock
info "Setting up Bitwarden..."
echo ""

# Check if already logged in
BW_STATUS=$(bw status | jq -r '.status')

if [ "$BW_STATUS" = "unauthenticated" ]; then
    info "Please log in to Bitwarden:"
    bw login < /dev/tty
    BW_STATUS=$(bw status | jq -r '.status')
fi

# Now handle unlock
if [ "$BW_STATUS" = "locked" ]; then
    info "Unlocking Bitwarden vault..."
    echo ""
    # Capture the session key directly from unlock
    BW_SESSION=$(bw unlock --raw < /dev/tty)
    export BW_SESSION
elif [ "$BW_STATUS" = "unlocked" ]; then
    info "Bitwarden vault already unlocked"
else
    error "Unexpected Bitwarden status: $BW_STATUS"
fi

# Verify Bitwarden is unlocked
if ! bw status | jq -e '.status == "unlocked"' > /dev/null 2>&1; then
    error "Bitwarden vault is not unlocked. Please try again."
fi

info "Bitwarden vault unlocked successfully"

# Sync vault to get latest items
info "Syncing Bitwarden vault..."
bw sync

# Initialize and apply chezmoi (or update if already initialized)
# Note: This will automatically trigger ansible-pull via run_after_apply.sh.tmpl hook
if [ -d "$HOME/.local/share/chezmoi" ]; then
    info "Updating dotfiles from $GITHUB_USER..."
    chezmoi update
else
    info "Initializing chezmoi with dotfiles from $GITHUB_USER..."
    chezmoi init --apply "$GITHUB_USER"
fi

echo ""
info "Bootstrap complete!"
echo ""
echo "Please restart your terminal or run: exec zsh"
echo ""
