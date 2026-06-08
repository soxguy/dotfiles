# ~/.config/zsh/path.zsh
#
# PATH modifications and core environment setup
# Loaded first to ensure all tools are available

# Local user binaries
export PATH="$HOME/.local/bin:$PATH"

# Snap packages (Linux only)
if [[ "$(uname)" == "Linux" ]]; then
    export PATH="/snap/bin:$PATH"
fi

# Opencode
export PATH="$HOME/.opencode/bin:$PATH"

# npm global
export PATH="$HOME/.npm-global/bin:$PATH"

# Initialize Homebrew
if [[ "$(uname)" == "Darwin" ]]; then
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    # Bitwarden desktop SSH agent
    export SSH_AUTH_SOCK="$HOME/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock"

    # VSCode CLI
    export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
elif [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Set default browser to wslview for WSL environments
if [[ -n "$WSL_DISTRO_NAME" ]]; then
    export BROWSER=wslview
fi
