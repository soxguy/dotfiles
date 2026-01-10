# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a chezmoi-managed dotfiles repository that uses Bitwarden CLI for secrets management. It's designed for Ubuntu/WSL2 environments and provides automated setup via bootstrap.sh.

## Core Architecture

### Secrets Management Flow

The repository uses a templating system where `.tmpl` files contain Bitwarden function calls that are evaluated during `chezmoi apply`:

1. **Template files** (`.tmpl` suffix) contain Bitwarden function calls
2. **chezmoi** processes templates and calls Bitwarden CLI via `bw` command
3. **Bitwarden CLI** must be unlocked with `BW_SESSION` environment variable set
4. **.zshrc wrapper** automatically unlocks Bitwarden before `chezmoi apply/update/init`

### Bitwarden Template Functions

Two primary functions are used in templates:

```
{{ (bitwarden "item" "Item Name").notes }}
{{ (bitwardenFields "item" "Item Name").FIELD_NAME.value }}
```

- `bitwarden` - retrieves the entire item, access `.notes` for notes field
- `bitwardenFields` - retrieves custom fields from an item

### Required Bitwarden Items

The repository expects these items in Bitwarden vault:

| Item Name | Type | Usage |
|-----------|------|-------|
| `SSH Key - GitHub` | Secure Note | Private key in Notes field → `~/.ssh/id_ed25519`<br>Custom field `passkey` (Hidden) → SSH key passphrase for auto-loading |
| `API Keys - zsh ENV` | Secure Note | Custom fields `HF_TOKEN`, `CLAUDE_CODE_OAUTH_TOKEN` → exported in `.zshrc` |

### File Naming Conventions

Chezmoi uses special prefixes/suffixes in source directory:

- `dot_` → file starts with `.` (e.g., `dot_zshrc` → `.zshrc`)
- `private_` → sets file permissions to `0600`
- `executable_` → adds execute permissions
- `.tmpl` → processes as template with Bitwarden function evaluation

Example: `private_dot_ssh/private_id_ed25519.tmpl` becomes `~/.ssh/id_ed25519` with `0600` permissions

## Common Commands

### Testing/Previewing Changes

```bash
# Preview what would change
chezmoi diff

# See what a template would generate
chezmoi cat ~/.zshrc

# View available template data
chezmoi data
```

### Applying Changes

```bash
# Edit a managed file
chezmoi edit ~/.zshrc

# Apply local changes to home directory
chezmoi apply

# Pull from git and apply
chezmoi update
```

### Managing Files

```bash
# Add existing file to chezmoi
chezmoi add ~/.config/some-file

# Add as template (for files needing secrets)
chezmoi add --template ~/.config/some-file

# Navigate to source directory
chezmoi cd

# List managed files
chezmoi managed
```

### Bitwarden Operations

```bash
# Unlock Bitwarden (exported by .zshrc)
bwunlock

# Sync vault (REQUIRED after adding/modifying items in Bitwarden web/app)
bw sync

# View item structure
bw get item "Item Name" | jq '.fields'
```

### Adding Environment Variables

The `.zshrc.tmpl` automatically exports all custom fields from "API Keys - zsh ENV":

1. Add custom field to "API Keys - zsh ENV" in Bitwarden (field name = env var name)
2. Run `bw sync` to pull changes locally
3. Run `chezmoi apply` to regenerate `.zshrc`
4. Run `exec zsh` to reload shell with new variables

No template changes needed - the loop handles all fields automatically.

## Working with Templates

When modifying `.tmpl` files:

1. Edit in source directory: `chezmoi edit <file>`
2. Test template rendering: `chezmoi cat <file>`
3. Verify Bitwarden field names: `bw get item "Item Name" | jq`
4. Apply and check: `chezmoi apply && cat <file>`

Common template error: "template has no entry for key" means the Bitwarden item name or field name doesn't match exactly.

## Bootstrap Script (bootstrap.sh)

New machine setup workflow:

1. Sets `PATH` to include `~/.local/bin` (where tools are installed)
2. Installs system packages via apt (git, zsh, vim, jq, etc.)
3. Installs Starship prompt to `~/.local/bin`
4. Installs chezmoi to `~/.local/bin`
5. Installs Bitwarden CLI as direct binary to `~/.local/bin`
6. Installs uv (Python package manager)
7. Handles Bitwarden login and unlock with session management
8. Syncs Bitwarden vault
9. Runs `chezmoi init --apply` (or `chezmoi update` if already initialized)
10. Changes default shell to zsh

The script uses `GITHUB_USER` environment variable (defaults to "soxguy") to determine the dotfiles repository.

## Repository Structure

```
~/.local/share/chezmoi/
├── bootstrap.sh                           # New machine setup
├── dot_zshrc.tmpl                        # Shell config with Bitwarden env vars
├── dot_config/
│   └── starship.toml                     # Prompt configuration
└── private_dot_ssh/
    ├── private_id_ed25519.tmpl           # SSH key from Bitwarden notes
    └── id_ed25519.pub                    # Public key (static)
```

## Key Implementation Details

### .zshrc Bitwarden Integration

The `.zshrc.tmpl` file:
- Defines `bwunlock()` function that checks `BW_SESSION` and unlocks if needed
- Wraps `chezmoi` command to auto-unlock before `apply/update/init` operations
- Exports environment variables by evaluating Bitwarden template functions at apply time
- Automatically loads SSH keys with passphrases from Bitwarden on shell startup

### SSH Key Auto-Loading

The `.zshrc.tmpl` automatically loads SSH keys on shell startup:

1. SSH agent starts/restores from saved state
2. If Bitwarden is unlocked, SSH key is auto-loaded using passphrase from vault
3. Key loading is skipped if already loaded (prevents redundant adds on subshells)

**How It Works**:
- Uses standard SSH_ASKPASS mechanism with temporary helper script
- Retrieves passphrase from `passkey` custom field in "SSH Key - GitHub" Bitwarden item
- Helper script created in /tmp with restrictive permissions, deleted immediately after use
- Only runs when both ssh-agent is running AND Bitwarden is unlocked

**Setup**:
1. Ensure "SSH Key - GitHub" item in Bitwarden has `passkey` custom field (Hidden type)
2. Run `bw sync` to pull changes locally
3. Run `chezmoi apply` to regenerate `.zshrc`
4. Start new shell - key will auto-load if Bitwarden is unlocked

**Note**: If Bitwarden is locked on shell startup, you'll see: "Note: SSH agent running, but SSH key not auto-loaded (Bitwarden locked)"

### Bootstrap Script Error Handling

- Uses `set -e` to exit on any error
- Checks tool existence before installation attempts
- Handles Bitwarden state machine: `unauthenticated` → `locked` → `unlocked`
- Uses `/dev/tty` for interactive prompts in piped execution context
- Supports re-running (updates instead of failing if chezmoi already initialized)
