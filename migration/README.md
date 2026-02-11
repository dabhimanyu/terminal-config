# Workstation Migration Scripts

This directory contains scripts for discovering and cataloging a complete workstation environment for migration to a new machine.

## Overview

The migration scripts follow a three-phase process:

1. **Discovery** - Catalog all installed packages, configurations, and tools
2. **Extraction** - Extract portable configurations to the repository
3. **Deployment** - Install configurations on the target machine

## Scripts

### `01_discover.sh` (Discovery)

Comprehensive discovery script that catalogs:

**Environment Discovery:**
- Python: versions, pip packages, pyenv versions, virtual environments
- Node.js: versions, NVM installation, global npm packages
- Shell configs: .zshrc, .bashrc, .shell_common, .profile, etc.

**Terminal/Editor Settings:**
- GNOME Terminal profiles (dconf export)
- Kitty terminal configuration
- Vim/Neovim configuration
- VSCode settings and extensions

**AI/Agent Configurations:**
- .claude (Claude Code CLI)
- .codex (Codex CLI)
- .gemini (Gemini CLI)
- .kimi (Kimi CLI)
- .agent (Agent configs)
- .mcp-servers (MCP servers)
- .continue (Continue.dev)
- .cursor (Cursor AI)

**Development Tools:**
- Git configuration and repositories inventory
- SSH public key inventory
- GPG key inventory
- Academic tools (Zotero, LaTeX)

**System Packages:**
- apt packages
- snap packages
- Flatpak applications

**Output:**
- `~/migration_package/` directory with:
  - `metadata/` - System info, version details
  - `configs/` - Configuration file copies
  - `exports/` - Package lists (pip freeze, npm list, etc.)
  - `inventories/` - Directory and file inventories
  - `checksums.txt` - SHA256 checksums for verification
  - `MANIFEST.txt` - Complete contents manifest

## Usage

### Phase 1: Discovery (Source Machine)

```bash
# Run discovery script
bash migration/01_discover.sh

# Review results
cat ~/migration_package/MANIFEST.txt

# Check package lists
cat ~/migration_package/exports/python_packages.txt
cat ~/migration_package/exports/npm_global.txt

# Review inventories
cat ~/migration_package/inventories/git_repos.txt
cat ~/migration_package/inventories/vscode_extensions.txt
```

### Phase 2: Extraction (Source Machine)

After discovery, extract portable configurations:

```bash
# Extract shell configs, fonts, terminal profiles
bash bash_scripts_/01_extract_config.sh

# Set up git repository
bash bash_scripts_/02_setup_git_repo.sh
```

### Phase 3: Deployment (Target Machine)

On the new workstation:

```bash
# Clone repository
git clone <your-repo-url> terminal-config
cd terminal-config

# Deploy all configurations
bash deployment/install.sh

# Validate installation
bash deployment/validate.sh
```

## Output Directory Structure

```
~/migration_package/
├── MANIFEST.txt              # Complete package manifest
├── checksums.txt             # SHA256 checksums
├── configs/                  # Configuration file copies
│   ├── .zshrc
│   ├── .bashrc
│   ├── .shell_common
│   ├── kitty.conf
│   └── vscode_settings/
├── exports/                  # Package lists
│   ├── python_packages.txt   # pip freeze
│   ├── npm_global.txt        # npm list -g
│   ├── apt_packages.txt      # apt list --installed
│   └── gnome-terminal.dconf  # Terminal settings
├── inventories/              # File/directory listings
│   ├── git_repos.txt         # All git repositories
│   ├── ssh_public_keys.txt   # SSH keys inventory
│   ├── gpg_keys.txt          # GPG keys inventory
│   ├── ai_config_dirs.txt    # AI/agent config directories
│   └── pyenv_versions.txt    # Python versions
└── metadata/                 # System information
    ├── system_info.txt       # Complete system snapshot
    ├── python_version.txt
    ├── node_version.txt
    └── ohmyzsh_info.txt
```

## Manual Transfer Required

The following items must be manually transferred (not included in discovery):

- **SSH private keys**: `~/.ssh/id_rsa`, `~/.ssh/id_ed25519`, etc.
- **GPG private keys**: Export with `gpg --export-secret-keys`
- **GPG trust database**: Export with `gpg --export-ownertrust > trust.txt`
- **Application data**: Browser profiles, application caches
- **Large datasets**: Research data, downloaded files

## Manual Transfer Commands

```bash
# SSH Keys
scp ~/.ssh/id_rsa* user@new-machine:~/.ssh/
scp ~/.ssh/id_ed25519* user@new-machine:~/.ssh/

# GPG Keys
gpg --export-secret-keys YOUR_KEY_ID > private-key.asc
gpg --export-ownertrust > trust.txt
# Transfer files, then on new machine:
gpg --import private-key.asc
gpg --import-ownertrust trust.txt
```

### `02_create_archive.sh` (Archive Creation)

Creates comprehensive migration archive from existing system.

**What it captures:**
- System package list (apt)
- Python/Node versions from version managers
- Shell configurations (.zshrc, .bashrc, .shell_common)
- Oh-My-Zsh framework and themes
- Terminal profiles (GNOME dconf) and fonts
- SSH and GPG keys (optional, prompts for confirmation)
- AI configurations (.claude, .codex, .cursor)
- VSCode settings and extensions list
- Zotero database (optional)
- Git repositories from workspace scan (optional)

**Usage:**
```bash
bash migration/02_create_archive.sh
```

**Output:**
- Archive: `~/terminal_backup_<timestamp>.tar.gz`
- Workspace: `~/terminal_migration_<timestamp>/`

### `03_deploy.sh` (Archive Deployment)

Deploys migration archive to new workstation.

**Usage:**
```bash
bash migration/03_deploy.sh <archive_path>
```

**Options:**
- `-d, --dry-run` - Simulate without making changes
- `-y, --yes` - Skip confirmation prompts
- `-v, --verbose` - Enable verbose output
- `-h, --help` - Show help message

**Deployment Order:**
1. System packages restore
2. Install version managers (nvm, pyenv)
3. Restore Python versions (pyenv)
4. Restore Node versions (nvm)
5. Deploy shell configs
6. Install oh-my-zsh and custom configs
7. Restore SSH and GPG keys (with permission fixes)
8. Restore AI configs
9. Restore terminal settings (GNOME dconf)
10. Restore VSCode settings and extensions
11. Restore Zotero database
12. Clone git repos
13. Set default shell

## Archive vs. Discovery Workflow

The migration system offers two approaches:

### Discovery Workflow (`01_discover.sh`)
- Use for: Understanding what's installed on a system
- Output: Readable inventories and package lists
- Transfer: Manual copy of discovered items
- Best for: Documentation, auditing, planning migrations

### Archive Workflow (`02_create_archive.sh` + `03_deploy.sh`)
- Use for: Complete workstation migration
- Output: Compressed tar.gz archive
- Transfer: Single file with all configurations
- Best for: Quick deployment to new machines

## Integration with Existing Workflow

The migration scripts integrate with the existing extraction workflow:

**Discovery/Archive Creation (Source Machine):**
1. `01_discover.sh` - Catalog everything (inventories only)
2. `02_create_archive.sh` - Create complete migration archive
3. `bash_scripts_/01_extract_config.sh` - Extract portable configs to repo
4. `bash_scripts_/02_setup_git_repo.sh` - Initialize git repository

**Deployment (Target Machine):**
5. `deployment/install.sh` - Deploy from git repository
6. `migration/03_deploy.sh` - Deploy from archive (alternative)
7. `deployment/validate.sh` - Verify deployment

### Archive Deployment Quick Start

```bash
# On source machine
bash migration/02_create_archive.sh

# Transfer archive securely
scp ~/terminal_backup_*.tar.gz user@target:~/

# On target machine
bash migration/03_deploy.sh ~/terminal_backup_*.tar.gz
```

### Secure Archive Transfer

Always encrypt archives containing sensitive data:

```bash
# Encrypt
gpg -c terminal_backup_20260111.tar.gz

# Transfer
scp terminal_backup_20260111.tar.gz.gpg user@target:~/

# Decrypt on target
gpg -d terminal_backup_20260111.tar.gz.gpg > terminal_backup_20260111.tar.gz

# Deploy
bash migration/03_deploy.sh terminal_backup_20260111.tar.gz
```

## Troubleshooting

**Discovery fails:**
- Ensure scripts are executable: `chmod +x migration/*.sh`
- Check available tools: The script gracefully handles missing tools

**Package exports empty:**
- Verify package managers are in PATH
- Check for permission issues (avoid sudo unless needed)

**Inventories incomplete:**
- Some directories may not be readable
- Adjust `find` depth for deeper/larger searches

**Archive deployment fails:**
- Check archive integrity: `tar -tzf archive.tar.gz | head`
- Review deployment log: `/tmp/migration_deploy_*.log`
- Use dry-run first: `bash migration/03_deploy.sh -d archive.tar.gz`

**SSH/GPG permission errors after deployment:**
```bash
# SSH
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/id_*.pub

# GPG
chmod 700 ~/.gnupg
find ~/.gnupg -type f -exec chmod 600 {} \;
find ~/.gnupg -type d -exec chmod 700 {} \;
```

**Font not appearing after deployment:**
```bash
fc-cache -f -v
fc-list | grep -i "JetBrains"
```

**VSCode extensions fail to install:**
```bash
# Install manually from list
cat ~/migration_package/configs/vscode_extensions.txt | while read ext; do
    code --install-extension "$ext"
done
```

## Related Documentation

- [AGENT.md](../AGENT.md) - Complete repository architecture
- [DEPLOY.md](../deployment/DEPLOY.md) - Deployment instructions
- [bash_scripts_/DEPLOY.md](../bash_scripts_/DEPLOY.md) - Extraction guide

## Version History

- **v1.1.0** (2026-02-11) - Archive deployment system
  - Added `02_create_archive.sh` for comprehensive archive creation
  - Added `03_deploy.sh` for automated deployment
  - Support for SSH/GPG key restoration with permission fixes
  - Support for AI configs, VSCode, Zotero migration
  - Dry-run mode and rollback capability
  - Secure transfer instructions

- **v1.0.0** (2026-02-11) - Initial discovery script
  - Comprehensive environment cataloging
  - Python, Node.js, shell, terminal, AI/agent discovery
  - Package export generation
  - Checksum verification support
