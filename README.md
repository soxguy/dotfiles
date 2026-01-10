# Dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io/) and [Bitwarden](https://bitwarden.com/) for secrets management.

## What's Included

- **zsh** configuration with [Starship](https://starship.rs/) prompt
- **SSH keys** pulled securely from Bitwarden
- **API keys** and tokens injected into shell environment
- **Bootstrap script** for automated setup of new machines

## Prerequisites

Before setting up a new machine, ensure the following items exist in your Bitwarden vault:

| Item Name | Type | Fields |
|-----------|------|--------|
| `SSH Key - GitHub` | Secure Note | Private key in the Notes field |
| `API Keys - zsh ENV` | Secure Note | Custom fields: `HF_TOKEN`, `CLAUDE_CODE_OAUTH_TOKEN` |

## Setting Up a New Machine

Run the bootstrap script on a fresh Ubuntu/WSL2 installation:

```bash
curl -fsSL https://raw.githubusercontent.com/soxguy/dotfiles/main/bootstrap.sh | bash
```

The script will:

1. Install essential packages (git, zsh, vim, jq, curl, etc.)
2. Install Starship prompt
3. Install chezmoi and Bitwarden CLI
4. Prompt you to log in and unlock Bitwarden
5. Initialize chezmoi and apply your dotfiles
6. Change your default shell to zsh

After completion, restart your terminal or run `exec zsh`.

## Day-to-Day Usage

### Updating Dotfiles on a Machine

Pull and apply the latest changes from the repo:

```bash
chezmoi update
```

This will prompt for Bitwarden unlock if needed (handled by the wrapper function in .zshrc).

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

## Making Changes to Dotfiles

### Editing an Existing File

```bash
# Open the file in your editor
chezmoi edit ~/.zshrc

# Preview changes
chezmoi diff

# Apply changes
chezmoi apply

# Commit and push
chezmoi cd
git add -A
git commit -m "Description of changes"
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

2. **Reference it in your template:**
   ```bash
   # For a custom field in an existing item
   {{ (bitwardenFields "item" "Item Name").field_name.value }}

   # For the notes field of an item
   {{ (bitwarden "item" "Item Name").notes }}
   ```

3. **Sync and apply:**
   ```bash
   bw sync
   chezmoi apply
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
~/.local/share/chezmoi/          # Chezmoi source directory
├── bootstrap.sh                  # New machine setup script
├── dot_zshrc.tmpl               # .zshrc template (contains Bitwarden refs)
├── dot_config/
│   └── starship.toml            # Starship prompt config
└── private_dot_ssh/
    ├── private_id_ed25519.tmpl  # SSH private key (from Bitwarden)
    └── id_ed25519.pub           # SSH public key
```

## Bitwarden Helper Commands

These are defined in .zshrc:

```bash
# Manually unlock Bitwarden
bwunlock

# chezmoi commands automatically call bwunlock when needed
chezmoi update  # unlocks first, then updates
chezmoi apply   # unlocks first, then applies
```

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