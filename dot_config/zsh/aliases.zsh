# ~/.config/zsh/aliases.zsh
#
# Command aliases for interactive shell use
# Only loaded for interactive shells (loader handles this)

# Better cat with syntax highlighting
alias bat='batcat'
alias cat='batcat'

# Modern ls replacement (exa)
alias l='exa --icons --group-directories-first --git --header'
alias ls='exa --icons --group-directories-first --git --header -1'
alias ll='exa --icons --group-directories-first --git --long --header'
alias la='exa --icons --group-directories-first --git --long --all --header'

# Quick navigation
alias cdr='cd ~/repos'
