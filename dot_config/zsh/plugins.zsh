# ~/.config/zsh/plugins.zsh
#
# Antidote plugin manager initialization
# Reads plugin declarations from ~/.zsh_plugins.txt
# Only loaded for interactive shells (loader handles this)

# Set zstyles for antidote configuration
zstyle ':antidote:bundle' use-friendly-names 'yes'

# Initialize antidote plugin manager (installed via Ansible)
source ${HOME}/.antidote/antidote.zsh
antidote load

# Enable fzf-tab completion (must be after antidote load)
enable-fzf-tab

# History substring search keybindings (must be after antidote load)
zmodload zsh/terminfo
[[ -n "$terminfo[kcuu1]" ]] && bindkey "$terminfo[kcuu1]" history-substring-search-up
[[ -n "$terminfo[kcud1]" ]] && bindkey "$terminfo[kcud1]" history-substring-search-down
