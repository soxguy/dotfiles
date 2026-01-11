# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a chezmoi-managed dotfiles repository that uses Ansible for system configuration and Bitwarden CLI for secrets management. It's designed for Ubuntu/WSL2 environments with a minimal bootstrap.sh that delegates to Ansible via ansible-pull.

## Core Architecture

### System Configuration (Ansible)

The repository uses a hybrid approach with chezmoi and Ansible:

1. **Bootstrap.sh** - Minimal script that installs only: Python, Ansible, chezmoi, Bitwarden CLI
2. **chezmoi** - Manages dotfiles, templates, and secrets from Bitwarden
3. **Ansible (ansible-pull)** - Manages system packages and tool installation via 8 roles
4. **Integration** - chezmoi hook (`run_after_apply.sh.tmpl`) triggers ansible-pull after every apply/update

**Workflow:** `chezmoi update` → pulls dotfiles → applies changes → runs ansible-pull → updates system packages

**Ansible roles:**
- system_packages: apt packages (git, zsh, vim, bat, eza, etc.)
- starship: Starship prompt
- bitwarden_cli: Bitwarden CLI
- uv: Python package manager
- homebrew: Homebrew
- nodejs: Node.js LTS
- claude_code: Claude Code CLI
- antidote: Zsh plugin manager

### Secrets Management Flow

The repository uses a templating system where `.tmpl` files contain Bitwarden function calls that are evaluated during `chezmoi apply`:

1. **Template files** (`.tmpl` suffix) contain Bitwarden function calls
2. **chezmoi** processes templates and calls Bitwarden CLI via `bw` command
3. **Bitwarden CLI** must be unlocked with `BW_SESSION` environment variable set
4. **~/.config/zsh/secrets.zsh** contains wrapper that automatically unlocks Bitwarden before `chezmoi apply/update/init`

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
| `ubuntu-USERNAME` | Login | Password field → Local account sudo password<br>Retrieved at runtime by ansible-pull for automated system updates<br>**Pattern:** `ubuntu-dawheat` for user `dawheat`, `ubuntu-foo` for user `foo` |

**Bitwarden Configuration Variables:**
- `BW_LOCAL_ACCT` - Automatically set to `ubuntu-USERNAME` pattern (e.g., `ubuntu-dawheat`)
- `BW_ENV_VARS_NOTE` - Item name for environment variables (default: `"API Keys - zsh ENV"`)

**Customization:** Override these in `~/.config/zsh/local.zsh` (not managed by chezmoi):
```bash
# Example ~/.config/zsh/local.zsh
export BW_LOCAL_ACCT="my-custom-sudo-item"
export BW_ENV_VARS_NOTE="My Custom ENV Vars"
```

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

The `~/.config/zsh/exports.zsh.tmpl` automatically exports all custom fields from "API Keys - zsh ENV":

1. Add custom field to "API Keys - zsh ENV" in Bitwarden (field name = env var name)
2. Run `bw sync` to pull changes locally
3. Run `chezmoi apply` to regenerate `~/.config/zsh/exports.zsh`
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

**New architecture:** Minimal bootstrap that installs only essentials and delegates to Ansible.

New machine setup workflow:

1. Sets `PATH` to include `~/.local/bin` (where tools are installed)
2. Installs bootstrap essentials via apt: git, python3, python3-pip, python3-apt, curl, unzip, jq
3. Installs Ansible (via PPA)
4. Installs chezmoi to `~/.local/bin`
5. Installs Bitwarden CLI as direct binary to `~/.local/bin`
6. Handles Bitwarden login and unlock with session management
7. Syncs Bitwarden vault
8. Runs `chezmoi init --apply` (or `chezmoi update` if already initialized)
9. **Triggers ansible-pull automatically** (via `run_after_apply.sh.tmpl` hook)

**What Ansible installs:**
- System packages: git, zsh, vim, bat, eza, and more (via system_packages role)
- Development tools: Starship, uv, Homebrew, Node.js, Claude Code (via respective roles)
- Zsh plugin manager: antidote (via antidote role)
- Changes default shell to zsh (post_task in ansible/local.yml)

The script uses `GITHUB_USER` environment variable (defaults to "soxguy") to determine the dotfiles repository.

## Repository Structure

```
~/.local/share/chezmoi/                    # Chezmoi source directory
├── bootstrap.sh                            # Minimal bootstrap (Ansible, chezmoi, Bitwarden)
├── run_after_apply.sh.tmpl                # Hook: triggers ansible-pull after chezmoi apply
│
├── ansible/                                # Ansible configuration
│   ├── local.yml                          # Main playbook for ansible-pull
│   └── roles/                             # Ansible roles (8 total)
│       ├── system_packages/               # Apt packages
│       ├── starship/                      # Starship prompt
│       ├── bitwarden_cli/                 # Bitwarden CLI
│       ├── uv/                            # Python package manager
│       ├── homebrew/                      # Homebrew
│       ├── nodejs/                        # Node.js LTS
│       ├── claude_code/                   # Claude Code CLI
│       └── antidote/                      # Zsh plugin manager
│
├── dot_zshrc                              # Minimal zsh loader
├── dot_zsh_plugins.txt                    # Antidote plugin declarations
│
├── dot_config/
│   ├── zsh/                               # Modular zsh configuration
│   │   ├── local.zsh.example              # Template for local overrides (copy to local.zsh)
│   │   ├── path.zsh                       # PATH modifications
│   │   ├── private_exports.zsh.tmpl       # Environment variables (from Bitwarden, 0600 perms)
│   │   ├── private_secrets.zsh.tmpl       # Bitwarden + SSH agent + key auto-loading (0600 perms)
│   │   ├── aliases.zsh                    # Command aliases
│   │   ├── plugins.zsh                    # Antidote setup
│   │   └── prompt.zsh                     # Starship initialization
│   └── starship.toml                      # Starship prompt theme
│
└── private_dot_ssh/
    ├── private_id_ed25519.tmpl            # SSH private key (from Bitwarden)
    └── id_ed25519.pub                     # SSH public key
```

## Key Implementation Details

### Modular ZSH Configuration

The zsh configuration is split into focused modules in `~/.config/zsh/`:

**Main loader (`dot_zshrc`):**
- Minimal file (~25 lines) that sources modular configs
- Sources `local.zsh` first to allow overrides
- Conditional sourcing: non-interactive shells only get PATH and exports
- Interactive shells get full configuration (secrets, aliases, plugins, prompt)

**Module files:**
- `local.zsh` - **Local machine overrides** (NOT managed by chezmoi, loaded first)
- `path.zsh` - PATH modifications (always loaded)
- `private_exports.zsh.tmpl` - Environment variables from Bitwarden (always loaded, 0600 perms)
- `private_secrets.zsh.tmpl` - Bitwarden integration + SSH agent (interactive only, 0600 perms)
- `aliases.zsh` - Command aliases (interactive only)
- `plugins.zsh` - Antidote plugin manager (interactive only)
- `prompt.zsh` - Starship prompt (interactive only)

**Using local.zsh for customization:**
The repository includes `~/.config/zsh/local.zsh.example` with documented override examples. To use:
```bash
cp ~/.config/zsh/local.zsh.example ~/.config/zsh/local.zsh
# Edit local.zsh and uncomment/modify settings as needed
```

Common overrides (see `local.zsh.example` for full documentation):
```bash
# Override Bitwarden item names
export BW_LOCAL_ACCT="custom-sudo-item"
export BW_ENV_VARS_NOTE="My ENV Vars"

# Add custom PATH entries
export PATH="/custom/bin:$PATH"

# Override aliases
alias ls='ls --color=auto'
```

**Note:** `local.zsh` is NOT managed by chezmoi - your changes persist across `chezmoi apply/update`.

### Bitwarden Integration

The `~/.config/zsh/private_secrets.zsh.tmpl` file:
- Defines `bwunlock()` function that checks `BW_SESSION` and unlocks if needed
- Wraps `chezmoi` command to auto-unlock before `apply/update/init` operations
- Manages SSH agent startup and restoration from saved state
- Automatically loads SSH keys with passphrases from Bitwarden on shell startup

The `~/.config/zsh/private_exports.zsh.tmpl` file:
- Exports environment variables by evaluating Bitwarden template functions at apply time
- Uses a loop to automatically export all custom fields from "API Keys - zsh ENV" item

### SSH Key Auto-Loading

The `~/.config/zsh/private_secrets.zsh.tmpl` automatically loads SSH keys on shell startup:

1. SSH agent starts/restores from saved state
2. If Bitwarden is unlocked, SSH key is auto-loaded using passphrase from vault
3. Key loading is skipped if already loaded (prevents redundant adds on subshells)

**How It Works**:
- Uses expect to automate ssh-add passphrase entry
- Retrieves passphrase from `passkey` custom field in "SSH Key - GitHub" Bitwarden item
- Passphrase handled in-memory only (never written to disk)
- Only runs when both ssh-agent is running AND Bitwarden is unlocked

**Setup**:
1. Ensure "SSH Key - GitHub" item in Bitwarden has `passkey` custom field (Hidden type)
2. Run `bw sync` to pull changes locally
3. Run `chezmoi apply` to regenerate `~/.config/zsh/secrets.zsh` (with 0600 permissions)
4. Start new shell - key will auto-load if Bitwarden is unlocked

**Note**: If Bitwarden is locked on shell startup, you'll see: "Note: SSH agent running, but SSH key not auto-loaded (Bitwarden locked)"

### Ansible Sudo Password Automation

The `run_after_apply.sh.tmpl` hook automatically retrieves your sudo password from Bitwarden to run ansible-pull without interactive prompts:

**How It Works**:
1. Hook sources `~/.config/zsh/exports.zsh` to get `BW_LOCAL_ACCT` environment variable (default: `ubuntu-USERNAME`)
2. Verifies Bitwarden vault is unlocked
3. Retrieves password using `bw get password "$BW_LOCAL_ACCT"`
4. If retrieval fails, automatically runs `bw sync` and retries once
5. Passes password to ansible-pull via `ANSIBLE_BECOME_PASS` environment variable
6. Ansible uses this password for all tasks with `become: yes`

**Benefits**:
- No interactive password prompts during `chezmoi update` or `chezmoi apply`
- Password never stored on disk (retrieved fresh each time)
- Automatic sync retry if item not found initially
- Username-based naming works across machines automatically
- Portable and secure (requires Bitwarden vault to be unlocked)

**Setup on New Machine**:
1. Create a Login item in Bitwarden following the naming pattern:
   - Item name: `ubuntu-USERNAME` (e.g., `ubuntu-dawheat` for user `dawheat`)
   - Password field: Your sudo password
2. Run `bw sync` to sync the vault (or let the hook auto-sync on first run)
3. Run `chezmoi init --apply` or `chezmoi update`
4. The hook automatically detects your username and retrieves the correct password
5. Future `chezmoi update` commands will work without password prompts

**Custom Item Name**:
If you prefer a different Bitwarden item name, create `~/.config/zsh/local.zsh`:
```bash
export BW_LOCAL_ACCT="my-custom-sudo-item"
```

**Troubleshooting**:
- If you see "Error: Bitwarden vault must be unlocked", run `bwunlock`
- If you see "Error: Failed to retrieve sudo password" after auto-sync:
  - Verify the item exists: `bw get item "ubuntu-USERNAME"`
  - Check item name matches: `echo $BW_LOCAL_ACCT`
  - Ensure password field is set in the Bitwarden item
- Password retrieval requires `BW_SESSION` environment variable (handled by `bwunlock`)

### Ubuntu Version Compatibility

The `system_packages` Ansible role automatically detects Ubuntu version and installs the correct packages:

**Package name variations**:
- **exa/eza**: Ubuntu 22.04 uses `exa`, Ubuntu 24.04+ uses `eza`
- The role uses Ansible's `set_fact` to conditionally set the package name based on `ansible_distribution_version`

This ensures the same dotfiles repository works across Ubuntu versions without manual modification.

### Bootstrap Script Error Handling

- Uses `set -e` to exit on any error
- Checks tool existence before installation attempts
- Handles Bitwarden state machine: `unauthenticated` → `locked` → `unlocked`
- Uses `/dev/tty` for interactive prompts in piped execution context
- Supports re-running (updates instead of failing if chezmoi already initialized)
