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
