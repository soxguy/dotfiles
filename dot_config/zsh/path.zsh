# ~/.config/zsh/path.zsh
#
# PATH modifications and core environment setup
# Loaded first to ensure all tools are available

# Local user binaries
export PATH="$HOME/.local/bin:$PATH"

# Snap packages
export PATH="/snap/bin:$PATH"

# Initialize Homebrew
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
