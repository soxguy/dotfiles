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

info "Starting bootstrap process..."

# Ensure ~/.local/bin exists
mkdir -p ~/.local/bin

# Update package lists
info "Updating package lists..."
sudo apt update

# Install essential packages
info "Installing essential packages..."
sudo apt install -y \
    git \
    bat \
    nala \
    eza \
    dnsutils \
    ca-certificates \
    mtr \
    jq \
    curl \
    build-essential \
    vim \
    zsh \
    unzip

# Install starship prompt
if ! command -v starship &> /dev/null; then
    info "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b ~/.local/bin
else
    info "Starship already installed"
fi

# Install chezmoi
if ! command -v chezmoi &> /dev/null; then
    info "Installing chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
else
    info "Chezmoi already installed"
fi

# Install Bitwarden CLI (direct binary, avoids snap/systemd issues on WSL2)
if ! command -v bw &> /dev/null; then
    info "Installing Bitwarden CLI..."
    curl -sL "https://vault.bitwarden.com/download/?app=cli&platform=linux" -o /tmp/bw.zip
    unzip -o /tmp/bw.zip -d ~/.local/bin
    chmod +x ~/.local/bin/bw
    rm /tmp/bw.zip
else
    info "Bitwarden CLI already installed"
fi

# Install uv (Python package manager)
if ! command -v uv &> /dev/null; then
    info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
else
    info "uv already installed"
fi

# Install Node.js (required for Claude Code)
if ! command -v node &> /dev/null; then
    info "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
else
    info "Node.js already installed"
fi

# Install Claude Code
if ! command -v claude-code &> /dev/null; then
    info "Installing Claude Code..."
    sudo npm install -g @anthropics/claude-code
    info "Configuring Claude Code onboarding..."
    echo '{"hasCompletedOnboarding": true}' > ~/.claude.json
else
    info "Claude Code already installed"
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
if [ -d "$HOME/.local/share/chezmoi" ]; then
    info "Updating dotfiles from $GITHUB_USER..."
    chezmoi update
else
    info "Initializing chezmoi with dotfiles from $GITHUB_USER..."
    chezmoi init --apply "$GITHUB_USER"
fi

# Change default shell to zsh
if [ "$SHELL" != "$(which zsh)" ]; then
    info "Changing default shell to zsh..."
    chsh -s "$(which zsh)" < /dev/tty
fi

echo ""
info "Bootstrap complete!"
echo ""
echo "Please restart your terminal or run: exec zsh"
echo ""