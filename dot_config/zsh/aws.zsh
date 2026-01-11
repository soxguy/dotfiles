# ~/.config/zsh/aws.zsh
#
# AWS CLI configuration and helper functions
# Loaded for interactive shells

# Default to personal config
export AWS_CONFIG_FILE="$HOME/.aws/config-personal"

# AWS profile switching functions
aws-personal() {
    export AWS_CONFIG_FILE="$HOME/.aws/config-personal"
    unset AWS_PROFILE
    echo "Switched to personal AWS config"
    aws configure list-profiles 2>/dev/null
}

aws-work() {
    if [[ -f "$HOME/.aws/config-work" && -s "$HOME/.aws/config-work" ]]; then
        export AWS_CONFIG_FILE="$HOME/.aws/config-work"
        unset AWS_PROFILE
        echo "Switched to work AWS config"
        aws configure list-profiles 2>/dev/null
    else
        echo "Error: Work AWS config not available on this machine"
        return 1
    fi
}

# Quick aliases
alias awslogin='aws sso login'
alias awswho='aws sts get-caller-identity'
alias awsprofiles='aws configure list-profiles'

# Optional: Profile switcher with fzf (uncomment to enable)
# awsp() {
#     local profile
#     profile=$(aws configure list-profiles | fzf --prompt="AWS Profile: ")
#     if [[ -n "$profile" ]]; then
#         export AWS_PROFILE="$profile"
#         echo "Selected profile: $profile"
#         aws sts get-caller-identity 2>/dev/null || echo "Run 'awslogin' to authenticate"
#     fi
# }
