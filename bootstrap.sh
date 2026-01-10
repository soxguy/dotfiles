#!/bin/bash
set -e

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

# Ensure ~/.local/bin exists and is in PATH
mkdir -p ~/.local/bin
export PATH="$HOME/.local/bin:/snap/bin:$PATH"

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

# Bitwarden login
info "Setting up Bitwarden..."
echo ""
warn "You need to log in to Bitwarden and unlock your vault."
echo ""

if ! bw login --check &> /dev/null; then
    info "Please log in to Bitwarden:"
    bw login
fi

echo ""
info "Please unlock your vault and export the session:"
echo ""
echo "  bw unlock"
echo ""
echo "Then run the export command it provides, e.g.:"
echo "  export BW_SESSION=\"your-session-key\""
echo ""
read -p "Press Enter after you've exported BW_SESSION..."

# Verify Bitwarden is unlocked
if ! bw status | jq -e '.status == "unlocked"' > /dev/null 2>&1; then
    error "Bitwarden vault is not unlocked. Please unlock and export BW_SESSION, then re-run this script."
fi

info "Bitwarden vault unlocked successfully"

# Initialize and apply chezmoi
info "Initializing chezmoi with dotfiles from $GITHUB_USER..."
chezmoi init --apply "$GITHUB_USER"

# Change default shell to zsh
if [ "$SHELL" != "$(which zsh)" ]; then
    info "Changing default shell to zsh..."
    chsh -s "$(which zsh)"
fi

echo ""
info "Bootstrap complete!"
echo ""
echo "Please restart your terminal or run: exec zsh"
echo ""
