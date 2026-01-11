# Dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io/), [Ansible](https://www.ansible.com/), and [Bitwarden](https://bitwarden.com/).

## What's Included

- **Modular zsh configuration** organized in `~/.config/zsh/` with [Starship](https://starship.rs/) prompt
- **Ansible-based system configuration** via ansible-pull for reproducible environments
- **SSH keys** pulled securely from Bitwarden with automatic passphrase loading
- **API keys** and tokens injected into shell environment from Bitwarden
- **Minimal bootstrap script** that installs essentials and delegates to Ansible
- **Automated sync workflow** - `chezmoi update` handles dotfiles and system packages

## Prerequisites

Before setting up a new machine, ensure the following items exist in your Bitwarden vault:

| Item Name | Type | Fields |
|-----------|------|--------|
| `SSH Key - GitHub` | Secure Note | **Notes:** Private key<br>**Custom field:** `passkey` (Hidden) - SSH key passphrase for auto-loading |
| `API Keys - zsh ENV` | Secure Note | Custom fields (any name = env var name): `HF_TOKEN`, `CLAUDE_CODE_OAUTH_TOKEN`, etc. |

## Setting Up a New Machine

Run the bootstrap script on a fresh Ubuntu/WSL2 installation:

```bash
curl -fsSL https://raw.githubusercontent.com/soxguy/dotfiles/main/bootstrap.sh | bash
```

The script will:

1. Install bootstrap essentials: Python, Ansible, chezmoi, Bitwarden CLI
2. Prompt you to log in and unlock Bitwarden
3. Initialize chezmoi and apply your dotfiles
4. **Trigger ansible-pull automatically** (via chezmoi hook) to install:
   - System packages (git, zsh, vim, bat, eza, etc.)
   - Development tools (Starship, uv, Homebrew, Node.js, Claude Code)
   - Change default shell to zsh

After completion, restart your terminal or run `exec zsh`.

**Architecture:** Bootstrap.sh is minimal and installs only what's needed to run Ansible. All system configuration is managed by Ansible roles, triggered automatically when chezmoi applies your dotfiles.

## Day-to-Day Usage

### Updating Dotfiles and System Packages

Pull and apply the latest changes from the repo:

```bash
chezmoi update
```

This single command will:
1. Prompt for Bitwarden unlock if needed (via wrapper in `~/.config/zsh/secrets.zsh`)
2. Pull latest dotfiles from git
3. Apply dotfile changes to home directory
4. **Run ansible-pull automatically** to update system packages and tools

**Note:** The chezmoi hook (`run_after_apply.sh.tmpl`) triggers ansible-pull after every update, ensuring your system stays synchronized.

### Viewing Pending Changes

See what chezmoi would change before applying:

```bash
chezmoi diff
```

### Applying Changes Without Pulling

If you've manually edited the chezmoi source directory:

```bash
chezmoi apply
```

## Making Changes

### Editing ZSH Configuration

The zsh config is now modular. To edit specific functionality:

```bash
# Edit PATH configuration
chezmoi edit ~/.config/zsh/path.zsh

# Edit aliases
chezmoi edit ~/.config/zsh/aliases.zsh

# Edit Bitwarden/SSH integration
chezmoi edit ~/.config/zsh/secrets.zsh

# Edit environment variables (template)
chezmoi edit ~/.config/zsh/exports.zsh

# Preview changes
chezmoi diff

# Apply changes
chezmoi apply

# Test in new shell
exec zsh

# Commit and push
chezmoi cd
git add -A
git commit -m "Description of changes"
git push
```

### Adding a System Package

To add a package managed by Ansible:

```bash
# Edit the system packages role
chezmoi edit ansible/roles/system_packages/tasks/main.yml

# Add package to the list under 'name:' section

# Apply and test
chezmoi apply  # Triggers ansible-pull automatically

# Commit and push
chezmoi cd
git add ansible/roles/system_packages/tasks/main.yml
git commit -m "Add [package-name] to system packages"
git push
```

### Adding a New Dotfile

```bash
# Add an existing file to chezmoi management
chezmoi add ~/.config/some-config

# For files that need Bitwarden secrets, add as a template
chezmoi add --template ~/.config/some-config

# Commit and push
chezmoi cd
git add -A
git commit -m "Add some-config"
git push
```

### Adding a New Secret

1. **Add the secret to Bitwarden:**
   - Add to an existing Secure Note as a custom field, or
   - Create a new Secure Note

2. **If using a template with loops** (like `~/.config/zsh/exports.zsh` for environment variables):
   - Simply add the custom field to the "API Keys - zsh ENV" Bitwarden item
   - No template changes needed - the loop will automatically export it

3. **If manually referencing in a template:**
   ```bash
   # For a custom field in an existing item
   {{ (bitwardenFields "item" "Item Name").field_name.value }}

   # For the notes field of an item
   {{ (bitwarden "item" "Item Name").notes }}
   ```

4. **Sync and apply:**
   ```bash
   bw sync          # Required: Pull latest changes from Bitwarden vault
   chezmoi apply
   exec zsh         # Reload shell to pick up new environment variables
   ```

## Chezmoi File Naming Conventions

Chezmoi uses special prefixes and suffixes in the source directory:

| Prefix/Suffix | Meaning |
|---------------|---------|
| `dot_` | File starts with `.` (e.g., `dot_zshrc` → `.zshrc`) |
| `private_` | File permissions set to `0600` |
| `executable_` | File permissions include execute bit |
| `create_` | Only create if file doesn't exist |
| `modify_` | Script that modifies existing file |
| `.tmpl` | Process as a template (for Bitwarden secrets) |

Example: `private_dot_ssh/private_id_ed25519.tmpl` becomes `~/.ssh/id_ed25519` with `0600` permissions, processed as a template.

## Directory Structure

```
~/.local/share/chezmoi/                    # Chezmoi source directory
├── bootstrap.sh                            # Minimal bootstrap (Ansible, chezmoi, Bitwarden)
├── run_after_apply.sh.tmpl                # Hook: triggers ansible-pull after chezmoi apply
│
├── ansible/                                # Ansible configuration
│   ├── local.yml                          # Main playbook for ansible-pull
│   └── roles/                             # Ansible roles (8 total)
│       ├── system_packages/               # Apt packages (git, zsh, vim, bat, eza, etc.)
│       ├── starship/                      # Starship prompt
│       ├── bitwarden_cli/                 # Bitwarden CLI
│       ├── uv/                            # Python package manager
│       ├── homebrew/                      # Homebrew
│       ├── nodejs/                        # Node.js LTS
│       ├── claude_code/                   # Claude Code CLI
│       └── antidote/                      # Zsh plugin manager
│
├── dot_zshrc                              # Minimal zsh loader (~25 lines)
├── dot_zsh_plugins.txt                    # Antidote plugin declarations
│
├── dot_config/
│   ├── zsh/                               # Modular zsh configuration
│   │   ├── path.zsh                       # PATH modifications
│   │   ├── exports.zsh.tmpl               # Environment variables (from Bitwarden)
│   │   ├── secrets.zsh.tmpl               # Bitwarden integration + SSH agent
│   │   ├── aliases.zsh                    # Command aliases
│   │   ├── plugins.zsh                    # Antidote setup
│   │   └── prompt.zsh                     # Starship initialization
│   └── starship.toml                      # Starship prompt theme
│
└── private_dot_ssh/
    ├── private_id_ed25519.tmpl            # SSH private key (from Bitwarden)
    └── id_ed25519.pub                     # SSH public key
```

## Bitwarden Helper Commands

These are defined in `~/.config/zsh/secrets.zsh`:

```bash
# Manually unlock Bitwarden
bwunlock

# chezmoi commands automatically call bwunlock when needed
chezmoi update  # unlocks first, then updates
chezmoi apply   # unlocks first, then applies
```

**Auto-loading SSH keys:** If Bitwarden is unlocked on shell startup, your SSH keys are automatically loaded with passphrases from the vault (see `~/.config/zsh/secrets.zsh`).

## Troubleshooting

### "Template has no entry for key"

The Bitwarden item or field name doesn't match. Check:

```bash
bw get item "Item Name" | jq '.fields'
```

### Bitwarden session expired

Run `bwunlock` or any chezmoi command (the wrapper handles it).

### Changes not appearing after push

On other machines, run:

```bash
chezmoi update
```

### Need to see the actual file chezmoi would generate

```bash
chezmoi cat ~/.zshrc
```

## Useful Commands Reference

| Command | Description |
|---------|-------------|
| `chezmoi update` | Pull latest from repo and apply |
| `chezmoi apply` | Apply local source to home directory |
| `chezmoi diff` | Show pending changes |
| `chezmoi edit <file>` | Edit a managed file |
| `chezmoi add <file>` | Start managing a file |
| `chezmoi add --template <file>` | Start managing as a template |
| `chezmoi cd` | Change to source directory |
| `chezmoi cat <file>` | Show what file would be generated |
| `chezmoi data` | Show template data |
| `chezmoi managed` | List all managed files |
| `chezmoi unmanaged` | List unmanaged files in home |
| `bwunlock` | Unlock Bitwarden and export session |