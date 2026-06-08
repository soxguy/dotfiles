# ~/.config/zsh/aliases.zsh
#
# Command aliases for interactive shell use
# Only loaded for interactive shells (loader handles this)

# Better cat with syntax highlighting
# Ubuntu apt installs bat as 'batcat'; macOS Homebrew installs as 'bat'
if command -v batcat &>/dev/null; then
    alias bat='batcat'
    alias cat='batcat'
elif command -v bat &>/dev/null; then
    alias cat='bat'
fi

# Modern ls replacement
alias l='eza --icons --group-directories-first --git --header'
alias ls='eza --icons --group-directories-first --git --header -1'
alias ll='eza --icons --group-directories-first --git --long --header'
alias la='eza --icons --group-directories-first --git --long --all --header'

# Quick navigation
alias cdr='cd ~/repos'

alias sudo='sudo '

# Alias Nala for package management (Linux only)
if (( $+commands[nala] )); then
  alias apt='nala'
fi
