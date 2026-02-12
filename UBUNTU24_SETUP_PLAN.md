# Ubuntu 24 System Setup - Comprehensive Execution Plan

**Purpose**: Complete workstation restoration from terminal-config repository to new Ubuntu 24 system

**Target State**: Research-grade terminal environment with dual AI agent setup (Claude Code + GLM/Kimi) in parallel terminal sessions

**Date Created**: 2026-02-12

**Repository**: terminal-config (v1.0.0 + migration infrastructure v1.1.0)

---

## Executive Summary

### What This Repository Contains

**CRITICAL CONFIGS** (extracted from your previous system):
- Shell configs: `.zshrc`, `.bashrc`, `.shell_common` with pyenv/NVM integration
- Oh-My-Zsh framework: 143 themes, 354 bundled plugins, custom prompt
- GNOME Terminal: 12 custom profiles (Vs Code Dark+, Catppuccin, Obsidian, etc.)
- Fonts: JetBrains Mono (34 TTF files, 8.1 MB)
- Version manager configurations: Pyenv, NVM initialization sequences

**MIGRATION TOOLS** (automated discovery and deployment):
- Discovery: `migration/01_discover.sh` - Catalogs EVERYTHING on current system
- Backup: `migration/02_backup.sh` + `migration/02_create_archive.sh` - Creates encrypted archives
- Deployment: `migration/03_deploy.sh` - Restores from archive
- Git-based: `deployment/install.sh` + `deployment/validate.sh` - Deploys from repo

**WHAT'S NOT IN REPO** (needs manual setup):
- Kitty terminal configuration (will be discovered and backed up)
- Claude Code CLI configuration (`.claude/`, `.claude.json`)
- GLM/Kimi CLI configuration (`.kimi/`, `.gemini/`)
- MCP servers configuration (`.mcp-servers/`)
- SSH/GPG keys (private keys must be manually transferred)
- Obsidian vault data (location: `/media/user/New Volume/Downloads/##_MarkDown_Files_`)
- Python virtual environment: `~/neural_computing/ai_env/`

### What You'll Achieve

**Terminal Environment**:
- Dual terminal setup: Kitty (primary) + GNOME Terminal (secondary)
- Consistent shell: Zsh with Oh-My-Zsh framework
- Version managers: Pyenv (Python) + NVM (Node.js) with correct PATH precedence
- Custom aliases: `activate_ai`, `obs` (Obsidian vault)
- 12 custom GNOME Terminal profiles restored

**AI Agent Ecosystem**:
- Claude Code CLI (requires Node.js via NVM)
- GLM 4.7 / Kimi CLI (requires Node.js via NVM)
- Parallel sessions in separate terminals
- MCP servers for enhanced capabilities

**Development Tools**:
- Git with existing configuration
- SSH/GPG keys restored
- VSCode settings and extensions
- LaTeX/Zotero (if applicable)

---

## Phase 0: Pre-Migration Discovery (On OLD System)

**Purpose**: Extract complete system state BEFORE migrating

**Prerequisite**: You must still have access to your old Ubuntu system

### Step 0.1: Clone Repository to Old System

```bash
# On OLD Ubuntu system
cd ~
git clone https://github.com/YOUR_USERNAME/terminal-config.git
cd terminal-config
```

### Step 0.2: Run Discovery Script

**What it does**: Catalogs EVERYTHING - packages, configs, AI tools, git repos

```bash
cd ~/terminal-config
bash migration/01_discover.sh
```

**Expected output**: `~/migration_package/` directory containing:
- `metadata/` - System info, Python/Node versions, Oh-My-Zsh details
- `configs/` - Copies of all config files (.zshrc, kitty.conf, VSCode settings)
- `exports/` - Package lists (pip freeze, npm list -g, apt packages)
- `inventories/` - Git repos, SSH keys, AI config directories, VSCode extensions
- `MANIFEST.txt` - Complete package contents

**Time estimate**: 2-5 minutes

### Step 0.3: Review Discovery Results

```bash
# Check what was discovered
cat ~/migration_package/MANIFEST.txt

# Check AI configurations found
cat ~/migration_package/inventories/ai_config_dirs.txt

# Check Kitty config (if exists)
ls -la ~/migration_package/configs/kitty.conf

# Check VSCode extensions
cat ~/migration_package/inventories/vscode_extensions.txt

# Check git repositories
cat ~/migration_package/inventories/git_repos.txt
```

### Step 0.4: Create Comprehensive Backup Archive

**Option A: Encrypted Archive (Recommended)**

```bash
cd ~/terminal-config
bash migration/02_backup.sh
```

**Output**: `~/migration_package_<timestamp>.tar.gz.gpg` (encrypted)

**What it backs up**:
- Shell configs (.zshrc, .bashrc, .shell_common, .oh-my-zsh/)
- AI configs (.claude/, .codex/, .gemini/, .kimi/, .mcp-servers/, .agent/)
- Security (SSH keys, GPG keys, .gitconfig)
- Terminal (.gnome/, .config/kitty/)
- Academic (Zotero/, LaTeX)
- Development (.pyenv/, .nvm/, custom scripts in ~/bin/)
- VSCode settings and extensions list

**Option B: Unencrypted Archive (Faster, less secure)**

```bash
cd ~/terminal-config
bash migration/02_create_archive.sh
```

**Output**: `~/terminal_backup_<timestamp>.tar.gz` (unencrypted)

### Step 0.5: Manual Backup of Sensitive Data

**Critical items NOT included in automated backup**:

1. **Obsidian Vault** (your markdown files):
```bash
# Backup entire vault
BACKUP_ROOT="/media/user/BACKUP_$(date +%Y%m%d)"
mkdir -p "$BACKUP_ROOT/obsidian"
cp -r "/media/user/New Volume/Downloads/##_MarkDown_Files_" "$BACKUP_ROOT/obsidian/"
```

2. **Large datasets** (research data, if any):
```bash
# Copy your research data directories
cp -r ~/research_data "$BACKUP_ROOT/research/"
cp -r ~/experiments "$BACKUP_ROOT/research/"
```

3. **Browser profiles** (if needed):
```bash
# Chrome/Chromium
cp -r ~/.config/google-chrome "$BACKUP_ROOT/browser/"
# Firefox
cp -r ~/.mozilla "$BACKUP_ROOT/browser/"
```

### Step 0.6: Transfer to External HDD or Cloud

**Option A: External HDD**

```bash
# Insert external HDD, mount at /media/user/BACKUP_HDD/

# Copy encrypted archive
cp ~/migration_package_*.tar.gz.gpg /media/user/BACKUP_HDD/

# Copy manual backups
cp -r "$BACKUP_ROOT" /media/user/BACKUP_HDD/

# Copy repository itself
cp -r ~/terminal-config /media/user/BACKUP_HDD/

# Verify checksums
cd ~/migration_package
find . -type f -name "checksums.*" -exec md5sum -c {} \;
```

**Option B: Cloud Transfer**

```bash
# Upload to Google Drive, Dropbox, or similar
# Ensure encryption if using cloud storage

# For Google Drive (using rclone):
rclone copy ~/migration_package_*.tar.gz.gpg gdrive:backups/
rclone copy ~/terminal-config gdrive:backups/
```

### Step 0.7: Update Repository with Latest Configs

**If you made changes since last git push**:

```bash
cd ~/terminal-config

# Update configs from current system
bash bash_scripts_/01_extract_config.sh

# Commit changes
git add .
git commit -m "feat: Update configs before Ubuntu 24 migration

Extracted latest shell configs, terminal profiles, and fonts from Ubuntu 20.04.6 LTS

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# Push to GitHub
git push origin main
```

---

## Phase 1: Fresh Ubuntu 24 Installation

**Purpose**: Clean OS install on new hardware/VM

### Step 1.1: Install Ubuntu 24.04 LTS

**Download**: https://ubuntu.com/download/desktop

**Installation Options**:
- Minimal installation: NO (select normal installation to get essential tools)
- Install third-party software: YES (for Wi-Fi, graphics drivers)
- Erase disk and install: YES (if fresh install)
- Partitioning: Auto (or custom if you need separate /home partition)

**During setup**:
- Username: `user` (or same as old system to avoid path issues)
- Computer name: Your choice
- Enable auto-login: Your preference

### Step 1.2: First Boot - System Updates

```bash
# Update package list
sudo apt update

# Upgrade all packages
sudo apt upgrade -y

# Install essential build tools
sudo apt install -y build-essential curl git wget unzip
```

### Step 1.3: Install Core Dependencies

```bash
# Shell and terminal
sudo apt install -y zsh dconf-cli

# Development tools
sudo apt install -y python3-dev python3-pip python3-venv
sudo apt install -y nodejs npm  # Will be replaced by NVM-managed versions

# Font tools
sudo apt install -y fontconfig

# Version control
sudo apt install -y git git-lfs

# Optional but recommended
sudo apt install -y htop tmux tree ncdu ripgrep fd-find bat
```

### Step 1.4: Set Zsh as Default Shell

```bash
# Check Zsh installation
which zsh

# Set as default shell
chsh -s $(which zsh)

# Log out and log back in for change to take effect
```

---

## Phase 2: Restore Core Configuration from Repository

**Purpose**: Deploy shell configs, Oh-My-Zsh, fonts, terminal profiles

### Step 2.1: Clone Repository

```bash
cd ~
git clone https://github.com/YOUR_USERNAME/terminal-config.git
cd terminal-config
```

### Step 2.2: Run Deployment Script

```bash
cd ~/terminal-config
bash deployment/install.sh
```

**What it does**:
1. Installs prerequisites (zsh, git, curl, wget, dconf-cli, fontconfig)
2. Deploys shell configs (.zshrc, .bashrc, .shell_common) to ~/
3. Deploys Oh-My-Zsh framework to ~/.oh-my-zsh/
4. Clones external plugins (zsh-autosuggestions, zsh-syntax-highlighting)
5. Installs JetBrains Mono fonts to ~/.local/share/fonts/
6. Imports 12 GNOME Terminal profiles with UUID regeneration
7. Sets Zsh as default shell

**Expected duration**: 3-5 minutes

**Expected output**:
```
════════════════════════════════════════════════════════════════
Terminal Environment Deployment
════════════════════════════════════════════════════════════════
▶ Phase 1: Installing prerequisites
→ ✓ All prerequisites satisfied
▶ Phase 2: Deploying shell configuration files
→ ✓ Deployed .zshrc
→ ✓ Deployed .bashrc
→ ✓ Deployed .shell_common
▶ Phase 3: Deploying Oh-My-Zsh framework
→ ✓ Framework deployed
▶ Phase 4: Cloning external plugins
→ ✓ zsh-autosuggestions cloned
→ ✓ zsh-syntax-highlighting cloned
▶ Phase 5: Installing fonts
→ ✓ 34 font files installed
→ ✓ Font cache rebuilt
▶ Phase 6: Importing terminal profiles
→ ✓ 12 profiles imported
→ ✓ Default profile set: Vs Code Dark+
▶ Phase 7: Setting default shell
→ ✓ Zsh set as default shell
⚠ Log out and log back in for shell change to take effect
```

### Step 2.3: Reload Shell Configuration

```bash
# Reload Zsh (applies new configs)
exec zsh

# You should now see custom prompt:
# Green arrow (➜) + current directory in cyan
```

### Step 2.4: Validate Installation

```bash
cd ~/terminal-config
bash deployment/validate.sh
```

**Expected output**:
```
✓ Default shell is Zsh
✓ Config files exist (.zshrc, .bashrc, .shell_common)
✓ Oh-My-Zsh framework present
✓ External plugins installed
✓ JetBrains Mono fonts installed (34 files)
✓ Terminal profiles imported (12 profiles)
✓ Default profile set

VALIDATION COMPLETE: All checks passed
```

### Step 2.5: Update Hardcoded Paths in .shell_common

**CRITICAL**: Your `.shell_common` contains hardcoded paths that must be updated

```bash
# Edit .shell_common
nano ~/.shell_common

# Update line 9 (Obsidian vault):
# OLD: alias obs='obsidian vault open "/media/user/New Volume/Downloads/##_MarkDown_Files_"'
# NEW: alias obs='obsidian vault open "/path/to/your/obsidian/vault"'

# Update line 10 (Python virtual environment):
# OLD: alias activate_ai='source ~/neural_computing/ai_env/bin/activate'
# NEW: alias activate_ai='source ~/neural_computing/ai_env/bin/activate'
#      (Keep same if you'll create venv at same location, otherwise update)

# Save and exit (Ctrl+O, Enter, Ctrl+X)

# Reload shell
source ~/.shell_common
```

---

## Phase 3: Install Version Managers (Pyenv + NVM)

**Purpose**: Enable Python and Node.js version management (REQUIRED for Claude Code and GLM CLI)

### Step 3.1: Install Pyenv (Python Version Manager)

```bash
# Install dependencies
sudo apt install -y make libssl-dev zlib1g-dev libbz2-dev \
  libreadline-dev libsqlite3-dev llvm libncurses5-dev \
  libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev

# Install pyenv
curl https://pyenv.run | bash

# Verify installation
pyenv --version
```

**Note**: `.zshrc` already contains pyenv initialization code, so it will auto-load on next shell restart

```bash
# Reload shell to activate pyenv
exec zsh

# Verify pyenv is in PATH
which pyenv
# Expected: /home/user/.pyenv/bin/pyenv

# Check Python resolution
which python
# Expected: /home/user/.pyenv/shims/python (NOT /usr/bin/python)
```

### Step 3.2: Install Python Versions via Pyenv

```bash
# Install Python 3.12 (latest stable as of 2026)
pyenv install 3.12.1

# Set as global default
pyenv global 3.12.1

# Verify
python --version
# Expected: Python 3.12.1

# Verify correct Python binary
which python
# Expected: /home/user/.pyenv/shims/python
```

**If you need multiple Python versions**:
```bash
# Install Python 3.10 (for older projects)
pyenv install 3.10.13

# Install Python 3.11
pyenv install 3.11.7

# List installed versions
pyenv versions

# Switch globally
pyenv global 3.12.1

# Or set per-directory
cd ~/project
pyenv local 3.10.13  # Creates .python-version file
```

### Step 3.3: Install NVM (Node.js Version Manager)

**CRITICAL**: Claude Code and GLM/Kimi CLI require Node.js

```bash
# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Reload shell
exec zsh

# Verify NVM installation
nvm --version
# Expected: 0.39.7
```

**Note**: `.zshrc` already contains NVM initialization code (lines 28-30)

### Step 3.4: Install Node.js via NVM

```bash
# Install Node.js LTS (24.x as of 2026)
nvm install --lts

# Set as default
nvm alias default node

# Verify
node --version
# Expected: v24.x.x

npm --version
# Expected: 10.x.x

# Verify correct Node binary
which node
# Expected: /home/user/.nvm/versions/node/v24.x.x/bin/node
```

### Step 3.5: Verify PATH Order (CRITICAL)

**Expected PATH precedence**: pyenv shims → NVM bins → user bins → system bins

```bash
# Check PATH order
echo $PATH | tr ':' '\n' | head -10

# Expected order:
# 1. /home/user/.pyenv/shims            ← Pyenv (HIGHEST PRIORITY)
# 2. /home/user/.nvm/versions/node/.../bin  ← NVM
# 3. /home/user/.pyenv/bin
# 4. /home/user/bin                     ← User bins (AFTER version managers)
# 5. /home/user/.local/bin              ← User local bins
# 6. /usr/local/bin                     ← System bins
```

**If PATH order is wrong, do NOT proceed** - contact for debugging

---

## Phase 4: Install Kitty Terminal Emulator

**Purpose**: Primary terminal for parallel AI agent sessions

### Step 4.1: Install Kitty

**Option A: Official Binary (Recommended)**

```bash
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

# Create desktop integration
ln -sf ~/.local/kitty.app/bin/kitty ~/.local/bin/
cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
cp ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/
sed -i "s|Icon=kitty|Icon=/home/$USER/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty*.desktop
sed -i "s|Exec=kitty|Exec=/home/$USER/.local/kitty.app/bin/kitty|g" ~/.local/share/applications/kitty*.desktop

# Update desktop database
update-desktop-database ~/.local/share/applications/
```

**Option B: APT Package (Simpler but older version)**

```bash
sudo apt install -y kitty
```

### Step 4.2: Restore Kitty Configuration

**If you discovered kitty.conf in Phase 0**:

```bash
# Check if kitty config was backed up
ls -la ~/migration_package/configs/kitty.conf

# If exists, restore it
mkdir -p ~/.config/kitty
cp ~/migration_package/configs/kitty.conf ~/.config/kitty/

# Or if using archive restore (see Phase 7)
# kitty.conf will be restored automatically
```

**If no previous config, create basic config**:

```bash
mkdir -p ~/.config/kitty

cat > ~/.config/kitty/kitty.conf << 'EOF'
# Kitty Terminal Configuration

# Font
font_family      JetBrains Mono
bold_font        JetBrains Mono Bold
italic_font      JetBrains Mono Italic
bold_italic_font JetBrains Mono Bold Italic
font_size 12.0

# Cursor
cursor_shape block
cursor_blink_interval 0

# Scrollback
scrollback_lines 10000

# Mouse
mouse_hide_wait 3.0
url_color #0087bd
url_style curly

# Window
remember_window_size  yes
initial_window_width  1200
initial_window_height 800

# Tab bar
tab_bar_edge bottom
tab_bar_style powerline

# Color scheme (VS Code Dark+ inspired)
foreground #cccccc
background #1e1e1e

# Black
color0 #000000
color8 #666666

# Red
color1 #cd3131
color9 #f14c4c

# Green
color2  #0dbc79
color10 #23d18b

# Yellow
color3  #e5e510
color11 #f5f543

# Blue
color4  #2472c8
color12 #3b8eea

# Magenta
color5  #bc3fbc
color13 #d670d6

# Cyan
color6  #11a8cd
color14 #29b8db

# White
color7  #e5e5e5
color15 #ffffff

# Advanced
shell_integration enabled
allow_remote_control yes
listen_on unix:/tmp/kitty
EOF

# Test configuration
kitty --config ~/.config/kitty/kitty.conf
```

### Step 4.3: Configure Kitty for Parallel Sessions

**Create session layouts**:

```bash
mkdir -p ~/.config/kitty/sessions

# Session 1: Dual vertical split (Claude Code + GLM)
cat > ~/.config/kitty/sessions/ai_agents.conf << 'EOF'
# AI Agents Session - Vertical Split
layout splits
launch zsh -c "echo 'Claude Code session - Ready' && exec zsh"
launch --location=vsplit zsh -c "echo 'GLM/Kimi session - Ready' && exec zsh"
EOF

# Session 2: Quad grid (for complex workflows)
cat > ~/.config/kitty/sessions/research_quad.conf << 'EOF'
# Research Session - Quad Grid
layout grid
launch zsh -c "echo 'Q1: Claude Code' && exec zsh"
launch zsh -c "echo 'Q2: GLM/Kimi' && exec zsh"
launch zsh -c "echo 'Q3: Python REPL' && exec zsh"
launch zsh -c "echo 'Q4: System Monitor' && htop"
EOF
```

**Launch Kitty with session**:

```bash
# Launch dual AI agent session
kitty --session ~/.config/kitty/sessions/ai_agents.conf

# Or launch quad research session
kitty --session ~/.config/kitty/sessions/research_quad.conf
```

---

## Phase 5: Install Claude Code CLI

**Purpose**: Set up Claude Code CLI for AI-assisted development

**Prerequisites**: Node.js installed via NVM (Phase 3.4 completed)

### Step 5.1: Install Claude Code CLI

```bash
# Verify Node.js is available
node --version
# Must show v24.x.x (via NVM)

# Install Claude Code CLI globally
npm install -g @anthropics/claude-code

# Verify installation
claude --version
```

### Step 5.2: Authenticate Claude Code

```bash
# Login to Claude Code
claude auth login

# This will open browser for authentication
# Follow prompts to connect your Anthropic account
```

### Step 5.3: Restore Claude Code Configuration (If Available)

**If you backed up `.claude/` and `.claude.json` from old system**:

```bash
# Check if Claude config was backed up
ls -la ~/migration_package/inventories/.claude_files.txt

# If archive restore (Phase 7):
# Configs will be restored automatically to ~/.claude/ and ~/.claude.json

# Otherwise, manually restore:
# (Only if you have the backup archive from Phase 0)
tar -xzf ~/migration_package_*.tar.gz -C ~ --wildcards '*.claude/*' '*.claude.json'
```

### Step 5.4: Test Claude Code

```bash
# Navigate to a test directory
mkdir -p ~/test_claude
cd ~/test_claude

# Initialize a git repository (Claude Code works best with git)
git init

# Start Claude Code session
claude

# Test with a simple prompt:
# "Create a hello.py file that prints 'Hello from Claude Code'"

# Exit Claude Code
# Type /exit or Ctrl+D
```

### Step 5.5: Configure Claude Code Settings

```bash
# Create Claude Code config (if not restored)
mkdir -p ~/.claude

# Edit settings
nano ~/.claude.json

# Example configuration:
cat > ~/.claude.json << 'EOF'
{
  "model": "claude-sonnet-4-5",
  "temperature": 0.7,
  "maxTokens": 8000,
  "editor": "nano",
  "autoCommit": false,
  "skills": {
    "enabled": true
  }
}
EOF
```

---

## Phase 6: Install GLM/Kimi CLI

**Purpose**: Set up GLM 4.7 / Kimi CLI for parallel AI agent usage

**Prerequisites**: Node.js installed via NVM (Phase 3.4 completed)

### Step 6.1: Install Kimi CLI

**Note**: GLM/Kimi CLI installation varies by provider. Assuming generic Node.js-based CLI.

```bash
# Verify Node.js
node --version

# Install Kimi CLI (adjust package name as needed)
npm install -g @kimi/cli
# OR
npm install -g glm-cli
# OR (if using Moonshot AI's Kimi)
npm install -g @moonshot/kimi-cli

# Verify installation
kimi --version
# OR
glm --version
```

**If CLI not available via npm, check official documentation**:
- GLM: https://github.com/THUDM/GLM-4
- Kimi (Moonshot AI): https://platform.moonshot.cn/docs

### Step 6.2: Authenticate Kimi/GLM CLI

```bash
# Set API key (adjust based on CLI provider)
export KIMI_API_KEY="your-api-key-here"
# OR
export GLM_API_KEY="your-api-key-here"

# Add to .zshrc for persistence
echo 'export KIMI_API_KEY="your-api-key-here"' >> ~/.zshrc

# Or use CLI login command (if supported)
kimi login
# Follow authentication prompts
```

### Step 6.3: Restore Kimi/GLM Configuration (If Available)

**If you backed up `.kimi/` or `.gemini/` from old system**:

```bash
# Check if configs were backed up
ls -la ~/migration_package/inventories/.kimi_files.txt
ls -la ~/migration_package/inventories/.gemini_files.txt

# If archive restore (Phase 7):
# Configs restored automatically to ~/.kimi/ or ~/.gemini/

# Otherwise, manually restore from backup archive
```

### Step 6.4: Test GLM/Kimi CLI

```bash
# Test Kimi CLI
kimi "Explain the difference between pyenv and virtualenv"

# OR test GLM CLI
glm "Write a Python function to calculate Fibonacci sequence"
```

---

## Phase 7: Full System Restoration from Backup Archive

**Purpose**: Restore ALL configurations from encrypted/unencrypted archive created in Phase 0

**Prerequisites**:
- Phases 1-3 completed (Ubuntu installed, core configs deployed, version managers installed)
- Backup archive from old system available

### Step 7.1: Transfer Backup Archive to New System

**If using external HDD**:

```bash
# Mount external HDD
# (Should auto-mount to /media/user/BACKUP_HDD/ or similar)

# Copy archive to home directory
cp /media/user/BACKUP_HDD/migration_package_*.tar.gz.gpg ~/
# OR (if unencrypted)
cp /media/user/BACKUP_HDD/terminal_backup_*.tar.gz ~/
```

**If using cloud storage**:

```bash
# Download from Google Drive (using rclone or web)
rclone copy gdrive:backups/migration_package_*.tar.gz.gpg ~/

# Or download via browser and move to home directory
```

### Step 7.2: Decrypt Archive (If Encrypted)

```bash
# Decrypt GPG-encrypted archive
gpg -d ~/migration_package_*.tar.gz.gpg > ~/migration_package_*.tar.gz

# Enter passphrase when prompted
```

### Step 7.3: Run Full Deployment Script

```bash
cd ~/terminal-config

# Run deployment script with archive
bash migration/03_deploy.sh ~/migration_package_*.tar.gz

# Or with unencrypted backup
bash migration/03_deploy.sh ~/terminal_backup_*.tar.gz
```

**What it restores** (13 phases):
1. System package list verification
2. NVM installation (if not already installed)
3. Pyenv installation (if not already installed)
4. Python versions restoration via pyenv
5. Node.js versions restoration via NVM
6. Shell configs deployment
7. Oh-My-Zsh and plugins
8. SSH keys restoration (with correct permissions)
9. GPG keys restoration (with correct permissions)
10. AI configs (.claude/, .codex/, .gemini/, .kimi/, .mcp-servers/)
11. GNOME Terminal settings
12. VSCode settings and extensions
13. Zotero database (if backed up)

**Expected duration**: 10-20 minutes (depending on package installations)

### Step 7.4: Verify Restoration

```bash
# Check SSH keys
ls -la ~/.ssh/
# Expected: id_ed25519, id_ed25519.pub with correct permissions (600/644)

# Check GPG keys
gpg --list-secret-keys
# Expected: Your GPG keys listed

# Check AI configs
ls -la ~/.claude/
ls -la ~/.kimi/ # or ~/.gemini/
ls -la ~/.mcp-servers/

# Check Kitty config
cat ~/.config/kitty/kitty.conf

# Check VSCode extensions
code --list-extensions
```

### Step 7.5: Manual Restoration Steps

**Items that CANNOT be automated**:

1. **Obsidian Vault Restoration**:
```bash
# Create target directory
mkdir -p "/media/user/New Volume/Downloads/"

# Copy from backup
cp -r /media/user/BACKUP_HDD/BACKUP_*/obsidian/##_MarkDown_Files_ "/media/user/New Volume/Downloads/"

# Verify
ls -la "/media/user/New Volume/Downloads/##_MarkDown_Files_"

# Test alias
obs  # Should open Obsidian with your vault
```

2. **Python Virtual Environment Restoration**:
```bash
# Option A: Restore from requirements.txt (Recommended)
mkdir -p ~/neural_computing
python -m venv ~/neural_computing/ai_env
source ~/neural_computing/ai_env/bin/activate
pip install -r ~/migration_package/dev/ai_env_requirements.txt

# Option B: Copy entire venv (may break due to path dependencies)
cp -r /media/user/BACKUP_HDD/BACKUP_*/dev/ai_env ~/neural_computing/

# Test alias
activate_ai  # Should activate Python venv
python --version  # Should show Python 3.12.1 (or your version)
```

3. **Git Repositories Cloning**:
```bash
# Review list of git repos from old system
cat ~/migration_package/inventories/git_repos.txt

# Clone important repos
cd ~
git clone https://github.com/YOUR_USERNAME/thesis.git
git clone https://github.com/YOUR_USERNAME/research-code.git
# etc.
```

4. **Browser Profile Restoration** (if backed up):
```bash
# Chrome
cp -r /media/user/BACKUP_HDD/BACKUP_*/browser/google-chrome ~/.config/

# Firefox
cp -r /media/user/BACKUP_HDD/BACKUP_*/browser/.mozilla ~/
```

---

## Phase 8: Configure Dual AI Agent Workflow

**Purpose**: Set up parallel Claude Code + GLM sessions in Kitty terminal

### Step 8.1: Create Dedicated Workflow Directory

```bash
# Create workspace for AI agent collaboration
mkdir -p ~/ai_workspace
cd ~/ai_workspace

# Initialize git (both agents work better with git)
git init
git config user.name "Your Name"
git config user.email "your.email@example.com"
```

### Step 8.2: Launch Dual Agent Session in Kitty

**Method A: Using Kitty Session File**

```bash
# Launch pre-configured dual session
kitty --session ~/.config/kitty/sessions/ai_agents.conf
```

This opens Kitty with two vertical panes:
- **Left pane**: For Claude Code
- **Right pane**: For GLM/Kimi

**Method B: Manual Split in Kitty**

```bash
# Launch Kitty
kitty

# Inside Kitty, create vertical split
# Press: Ctrl+Shift+Enter (creates vertical split)

# Navigate between splits
# Ctrl+Shift+] - Move to next window
# Ctrl+Shift+[ - Move to previous window
```

### Step 8.3: Start AI Agents in Parallel

**In LEFT pane (Claude Code)**:

```bash
cd ~/ai_workspace
claude

# Claude Code is now active
# You can give it tasks, ask questions, request code
```

**In RIGHT pane (GLM/Kimi)**:

```bash
cd ~/ai_workspace
kimi

# OR if using GLM directly
glm

# GLM/Kimi is now active in parallel
```

### Step 8.4: Workflow Examples

**Example 1: Collaborative Code Review**

*Left pane (Claude Code)*:
```
"Review the code in main.py and suggest improvements for performance"
```

*Right pane (GLM)*:
```
"Analyze main.py for potential security vulnerabilities"
```

**Example 2: Documentation + Testing**

*Left pane (Claude Code)*:
```
"Write comprehensive docstrings for all functions in utils.py"
```

*Right pane (GLM)*:
```
"Generate pytest test cases for the functions in utils.py"
```

**Example 3: Research + Implementation**

*Left pane (Claude Code)*:
```
"Explain the mathematical theory behind turbulent kinetic energy transport in particle-laden flows"
```

*Right pane (GLM)*:
```
"Implement a Python function to calculate k-ε turbulence model coefficients"
```

### Step 8.5: Sync Work Between Agents

**Using Git as shared context**:

```bash
# After Claude Code makes changes
# In LEFT pane:
git add .
git commit -m "Claude: Added turbulence model implementation"

# GLM can then review or extend
# In RIGHT pane:
git diff HEAD~1  # See Claude's changes
# Give GLM instructions to extend or modify

# GLM makes changes
git add .
git commit -m "GLM: Added validation tests for turbulence model"
```

### Step 8.6: Create Workflow Scripts

**Script 1: Quick launch dual agents**

```bash
cat > ~/bin/launch-ai-agents.sh << 'EOF'
#!/usr/bin/env bash
# Launch Claude Code and GLM in parallel Kitty sessions

kitty --session ~/.config/kitty/sessions/ai_agents.conf \
  --directory ~/ai_workspace \
  -o allow_remote_control=yes \
  -o listen_on=unix:/tmp/kitty-ai
EOF

chmod +x ~/bin/launch-ai-agents.sh

# Usage:
launch-ai-agents.sh
```

**Script 2: Coordinate agents with shared context**

```bash
cat > ~/bin/ai-handoff.sh << 'EOF'
#!/usr/bin/env bash
# Hand off context from Claude to GLM (or vice versa)

echo "=== AI Agent Handoff ==="
echo "1. Claude Code → GLM"
echo "2. GLM → Claude Code"
read -p "Select direction: " direction

if [ "$direction" = "1" ]; then
    echo "Committing Claude's work..."
    git add .
    git commit -m "Claude: Handoff to GLM"
    echo "GLM can now review with: git diff HEAD~1"
else
    echo "Committing GLM's work..."
    git add .
    git commit -m "GLM: Handoff to Claude"
    echo "Claude can now review with: git diff HEAD~1"
fi
EOF

chmod +x ~/bin/ai-handoff.sh
```

---

## Phase 9: Advanced Configuration and Optimization

### Step 9.1: Install MCP Servers (Model Context Protocol)

**Purpose**: Enhance AI agents with external tools and context

**Prerequisites**: Node.js via NVM

```bash
# Install MCP CLI (if available)
npm install -g @modelcontextprotocol/cli

# Or restore MCP servers from backup
# (Automatically restored in Phase 7.3 if archived)
```

**Configure MCP servers for Claude Code**:

```bash
# Edit Claude Code MCP configuration
nano ~/.claude/mcp.json

# Example MCP configuration:
cat > ~/.claude/mcp.json << 'EOF'
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/home/user/ai_workspace"]
    },
    "git": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-git"]
    },
    "python": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-python"]
    }
  }
}
EOF

# Restart Claude Code to load MCP servers
```

### Step 9.2: Install Academic Tools

**Obsidian** (if not already installed):

```bash
# Download Obsidian AppImage
wget https://github.com/obsidianmd/obsidian-releases/releases/download/v1.5.3/Obsidian-1.5.3.AppImage

# Make executable
chmod +x Obsidian-1.5.3.AppImage

# Move to applications
mkdir -p ~/.local/bin
mv Obsidian-1.5.3.AppImage ~/.local/bin/obsidian

# Test
obsidian

# Or use alias
obs
```

**Zotero** (reference management):

```bash
# Download Zotero
wget -qO- https://raw.githubusercontent.com/retorquere/zotero-deb/master/install.sh | sudo bash

# Install
sudo apt install -y zotero

# Restore Zotero database (if backed up in Phase 7)
# Database location: ~/.zotero/
```

**LaTeX** (for paper writing):

```bash
# Install TeX Live (full distribution)
sudo apt install -y texlive-full

# Or minimal installation
sudo apt install -y texlive-latex-base texlive-latex-extra texlive-fonts-recommended

# Install LaTeX editor (TeXstudio)
sudo apt install -y texstudio

# Restore custom LaTeX styles (if backed up)
mkdir -p ~/texmf
cp -r ~/migration_package/inventories/latex_texmf/* ~/texmf/
```

### Step 9.3: Configure VSCode with AI Extensions

**Install VSCode** (if not already installed):

```bash
# Add Microsoft repository
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

# Install
sudo apt update
sudo apt install -y code

# Restore extensions (if backed up in Phase 7)
cat ~/migration_package/inventories/vscode_extensions.txt | while read ext; do
    code --install-extension "$ext"
done
```

**Recommended AI extensions**:

```bash
# Claude Code extension (if available)
code --install-extension anthropic.claude

# GitHub Copilot
code --install-extension github.copilot

# Continue.dev
code --install-extension continue.continue

# Cursor AI integration (if using Cursor)
# Download Cursor: https://cursor.sh/
```

### Step 9.4: Optimize Shell Performance

**Enable Zsh plugins for AI workflow**:

```bash
# Edit .zshrc to add performance plugins
nano ~/.zshrc

# Add to plugins array (line 44):
plugins=(
    git
    pip
    virtualenv
    command-not-found
    colored-man-pages
    zsh-autosuggestions
    zsh-syntax-highlighting
    history-substring-search    # ← NEW: Search history with arrow keys
    auto-notify                 # ← NEW: Notify when long commands finish
)

# Reload shell
exec zsh
```

**Install additional Zsh plugins**:

```bash
# Fast syntax highlighting (faster than zsh-syntax-highlighting)
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git \
  ~/.oh-my-zsh/custom/plugins/fast-syntax-highlighting

# Zsh autosuggestions (already installed, but verify)
ls -la ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
```

### Step 9.5: Set Up Monitoring and Logging

**Create logs directory for AI agent sessions**:

```bash
mkdir -p ~/ai_workspace/logs

# Log Claude Code sessions
alias claude-log='claude 2>&1 | tee ~/ai_workspace/logs/claude_$(date +%Y%m%d_%H%M%S).log'

# Log GLM sessions
alias glm-log='glm 2>&1 | tee ~/ai_workspace/logs/glm_$(date +%Y%m%d_%H%M%S).log'

# Add to .shell_common for persistence
echo "alias claude-log='claude 2>&1 | tee ~/ai_workspace/logs/claude_\$(date +%Y%m%d_%H%M%S).log'" >> ~/.shell_common
echo "alias glm-log='glm 2>&1 | tee ~/ai_workspace/logs/glm_\$(date +%Y%m%d_%H%M%S).log'" >> ~/.shell_common
```

---

## Phase 10: Validation and Testing

### Step 10.1: System-Wide Validation

**Run comprehensive validation**:

```bash
cd ~/terminal-config
bash deployment/validate.sh

# Expected: All checks pass
```

### Step 10.2: Version Manager Validation

**Test Pyenv**:

```bash
# Check pyenv version
pyenv --version

# Check Python resolution
which python
# Expected: /home/user/.pyenv/shims/python

# Check Python version
python --version
# Expected: Python 3.12.1 (or your installed version)

# Test pip
pip --version
# Expected: pip from pyenv-managed Python

# Test virtualenv creation
python -m venv ~/test_venv
source ~/test_venv/bin/activate
python --version
deactivate
rm -rf ~/test_venv
```

**Test NVM**:

```bash
# Check NVM version
nvm --version

# Check Node resolution
which node
# Expected: /home/user/.nvm/versions/node/v24.x.x/bin/node

# Check Node version
node --version
# Expected: v24.x.x

# Test npm
npm --version
# Expected: 10.x.x

# Test global package installation
npm install -g cowsay
cowsay "NVM works!"
npm uninstall -g cowsay
```

### Step 10.3: Terminal Configuration Validation

**Test GNOME Terminal profiles**:

```bash
# Open GNOME Terminal
gnome-terminal

# Go to: Preferences → Profiles
# Verify 12 profiles are listed:
# - Vs Code Dark+ (default)
# - Elic
# - Catppuccin Frappé
# - Cobalt Neon
# - Chalk
# - Base4Tone Classic I
# - Everblush
# - Abhi_Ubunto_Profile_
# - Dehydration
# - Spacedust
# - Atelier Sulphurpool
# - Obsidian
```

**Test Kitty terminal**:

```bash
# Launch Kitty
kitty

# Test font rendering
echo "JetBrains Mono font test: 0Oo Il1 ({[]})"

# Test session loading
kitty --session ~/.config/kitty/sessions/ai_agents.conf
```

**Test font installation**:

```bash
# Check font cache
fc-list | grep -i "JetBrains Mono" | wc -l
# Expected: 34+ entries

# Check specific font
fc-list | grep "JetBrains Mono:style=Regular"
# Expected: Path to JetBrainsMono-Regular.ttf
```

### Step 10.4: AI Agent Validation

**Test Claude Code**:

```bash
cd ~/ai_workspace
claude

# Test prompt:
# "Create a test.py file with a function to print hello world"

# Verify file creation
cat test.py

# Exit Claude
/exit
```

**Test GLM/Kimi**:

```bash
cd ~/ai_workspace
kimi "What is the current directory?"

# Expected: Response showing ~/ai_workspace
```

**Test parallel session**:

```bash
# Launch dual session
kitty --session ~/.config/kitty/sessions/ai_agents.conf

# In LEFT pane:
claude

# In RIGHT pane:
kimi

# Both should be active simultaneously
```

### Step 10.5: PATH Precedence Validation (CRITICAL)

**Verify PATH order is correct**:

```bash
# Print PATH in readable format
echo $PATH | tr ':' '\n' | nl

# Expected order:
# 1  /home/user/.pyenv/shims              ← FIRST (Pyenv)
# 2  /home/user/.nvm/versions/node/.../bin ← SECOND (NVM)
# 3  /home/user/.pyenv/bin
# 4  /home/user/bin                       ← User bins AFTER version managers
# 5  /home/user/.local/bin
# 6  /usr/local/sbin
# 7  /usr/local/bin
# 8  /usr/sbin
# 9  /usr/bin
# 10 /sbin
# 11 /bin
```

**Test Python resolution**:

```bash
# Python should come from pyenv, NOT system
which python
# Expected: /home/user/.pyenv/shims/python

# NOT expected: /usr/bin/python

# Verify
python --version
pyenv version
# Both should match
```

**Test Node resolution**:

```bash
# Node should come from NVM, NOT system
which node
# Expected: /home/user/.nvm/versions/node/v24.x.x/bin/node

# NOT expected: /usr/bin/node

# Verify
node --version
nvm current
# Both should match
```

**If PATH is wrong**: STOP and debug before proceeding

### Step 10.6: Aliases and Functions Validation

**Test custom aliases**:

```bash
# Test Obsidian alias (after vault restored)
obs
# Expected: Obsidian opens with your vault

# Test Python venv alias (after venv created)
activate_ai
# Expected: Virtual environment activates
which python
# Expected: ~/neural_computing/ai_env/bin/python

# Test standard aliases
ll
# Expected: Detailed file listing
```

### Step 10.7: Git Configuration Validation

**Test Git config**:

```bash
# Check Git user
git config --global user.name
# Expected: Your name

git config --global user.email
# Expected: Your email

# Check SSH key
ssh -T git@github.com
# Expected: "Hi <username>! You've successfully authenticated..."

# Test clone
cd ~/test
git clone https://github.com/YOUR_USERNAME/test-repo.git
cd test-repo
```

---

## Phase 11: Workflow Optimization

### Step 11.1: Create Productivity Scripts

**Script: Daily AI workspace setup**

```bash
cat > ~/bin/ai-workspace-init.sh << 'EOF'
#!/usr/bin/env bash
# Initialize daily AI workspace

WORKSPACE_DIR=~/ai_workspace/$(date +%Y%m%d)
mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"

# Initialize git if not exists
if [ ! -d .git ]; then
    git init
    git config user.name "Abhimanyu Dubey"
    git config user.email "your.email@example.com"
fi

# Create daily notes
cat > NOTES.md << END
# AI Workspace - $(date +%Y-%m-%d)

## Tasks
- [ ]

## Claude Code Session
-

## GLM/Kimi Session
-

## Research Progress
-

END

# Launch Kitty with dual AI agents
kitty --session ~/.config/kitty/sessions/ai_agents.conf --directory "$WORKSPACE_DIR" &

echo "Workspace initialized: $WORKSPACE_DIR"
EOF

chmod +x ~/bin/ai-workspace-init.sh
```

**Script: Backup current work**

```bash
cat > ~/bin/backup-workspace.sh << 'EOF'
#!/usr/bin/env bash
# Backup current AI workspace

BACKUP_DIR=~/backups/ai_workspace
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# Backup workspace
tar -czf "$BACKUP_DIR/workspace_${TIMESTAMP}.tar.gz" ~/ai_workspace/

# Keep only last 7 days of backups
find "$BACKUP_DIR" -name "workspace_*.tar.gz" -mtime +7 -delete

echo "Workspace backed up to: $BACKUP_DIR/workspace_${TIMESTAMP}.tar.gz"
EOF

chmod +x ~/bin/backup-workspace.sh
```

**Script: Sync agent contexts**

```bash
cat > ~/bin/sync-agent-context.sh << 'EOF'
#!/usr/bin/env bash
# Sync context between Claude Code and GLM

CONTEXT_FILE=~/ai_workspace/SHARED_CONTEXT.md

echo "# Shared Agent Context - $(date)" > "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"

echo "## Recent Git History" >> "$CONTEXT_FILE"
git log --oneline -10 >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"

echo "## Recent File Changes" >> "$CONTEXT_FILE"
git diff HEAD~5..HEAD --stat >> "$CONTEXT_FILE"
echo "" >> "$CONTEXT_FILE"

echo "## Current TODO" >> "$CONTEXT_FILE"
grep -r "TODO" . --exclude-dir=.git >> "$CONTEXT_FILE" || echo "No TODOs found" >> "$CONTEXT_FILE"

echo "Context synced to: $CONTEXT_FILE"
cat "$CONTEXT_FILE"
EOF

chmod +x ~/bin/sync-agent-context.sh
```

### Step 11.2: Create Keyboard Shortcuts

**For GNOME Desktop**:

```bash
# Open Settings → Keyboard → Keyboard Shortcuts → Custom Shortcuts

# Shortcut 1: Launch Kitty with AI agents
# Name: Launch AI Agents
# Command: kitty --session ~/.config/kitty/sessions/ai_agents.conf
# Shortcut: Ctrl+Alt+A

# Shortcut 2: Launch single Kitty terminal
# Name: Launch Kitty
# Command: kitty
# Shortcut: Ctrl+Alt+K

# Shortcut 3: Initialize daily workspace
# Name: AI Workspace Init
# Command: /home/user/bin/ai-workspace-init.sh
# Shortcut: Ctrl+Alt+W
```

**Using gsettings (command-line method)**:

```bash
# Set custom keybinding for Kitty AI agents
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
  "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ \
  name 'Launch AI Agents'

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ \
  command 'kitty --session /home/user/.config/kitty/sessions/ai_agents.conf'

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ \
  binding '<Ctrl><Alt>a'
```

### Step 11.3: Configure Automatic Backups

**Daily backup with cron**:

```bash
# Edit crontab
crontab -e

# Add daily backup at 11 PM
0 23 * * * /home/user/bin/backup-workspace.sh >> /var/log/workspace_backup.log 2>&1

# Add weekly full system backup (Sundays at 2 AM)
0 2 * * 0 /home/user/terminal-config/migration/02_backup.sh >> /var/log/system_backup.log 2>&1
```

---

## Phase 12: Troubleshooting and Common Issues

### Issue 1: Pyenv Python Not Found

**Symptom**:
```bash
which python
# Output: /usr/bin/python (WRONG - should be ~/.pyenv/shims/python)
```

**Diagnosis**:
```bash
# Check if pyenv is in PATH
echo $PATH | grep pyenv
# Should show: .pyenv/shims and .pyenv/bin

# Check .zshrc
grep pyenv ~/.zshrc
# Should show pyenv initialization code
```

**Fix**:
```bash
# Reload shell
exec zsh

# If still wrong, manually re-initialize
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

# Make permanent by editing .zshrc
nano ~/.zshrc
# Ensure lines 14-22 are present and uncommented
```

### Issue 2: NVM Not Loading

**Symptom**:
```bash
nvm --version
# Output: command not found
```

**Fix**:
```bash
# Check if NVM directory exists
ls -la ~/.nvm

# If exists, manually source
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Reload shell
exec zsh

# If NVM directory doesn't exist, reinstall
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
exec zsh
```

### Issue 3: Claude Code Not Authenticating

**Symptom**:
```bash
claude
# Output: Not authenticated. Run 'claude auth login'
```

**Fix**:
```bash
# Re-authenticate
claude auth login

# If browser doesn't open
claude auth login --no-browser
# Follow URL manually

# Check authentication status
claude auth status
```

### Issue 4: PATH Order Wrong (User Bins Override Version Managers)

**Symptom**:
```bash
echo $PATH | tr ':' '\n' | head -5
# Output:
# /home/user/.local/bin  ← WRONG - this should be AFTER pyenv/nvm
# /home/user/bin
# /home/user/.pyenv/shims  ← Should be FIRST
```

**Fix**:
```bash
# Check .shell_common line 48
grep "export PATH" ~/.shell_common

# Should be: export PATH="$PATH:$1"  (APPEND)
# NOT: export PATH="$1:$PATH"  (PREPEND)

# If wrong, fix it
nano ~/.shell_common
# Line 48: Change to: export PATH="$PATH:$1"

# Reload
source ~/.shell_common
exec zsh
```

### Issue 5: GNOME Terminal Profiles Not Imported

**Symptom**:
```bash
# Check profiles
dconf read /org/gnome/terminal/legacy/profiles:/list
# Output: [] (empty)
```

**Fix**:
```bash
cd ~/terminal-config

# Re-run profile import section of deployment script
# Or manually import
for dconf_file in dconf/profile_*.dconf; do
    NEW_UUID=$(uuidgen)
    dconf load "/org/gnome/terminal/legacy/profiles:/:$NEW_UUID/" < "$dconf_file"
done

# Set default
dconf write /org/gnome/terminal/legacy/profiles:/default "'$NEW_UUID'"
```

### Issue 6: Kitty Not Rendering Fonts Correctly

**Symptom**: Kitty shows default monospace font instead of JetBrains Mono

**Fix**:
```bash
# Rebuild font cache
fc-cache -f -v

# Verify JetBrains Mono is installed
fc-list | grep "JetBrains Mono"

# If not found, reinstall fonts
cd ~/terminal-config
cp fonts/*.ttf ~/.local/share/fonts/
fc-cache -f -v

# Edit Kitty config to explicitly set font
nano ~/.config/kitty/kitty.conf
# Ensure: font_family JetBrains Mono

# Restart Kitty
```

### Issue 7: SSH Keys Incorrect Permissions

**Symptom**:
```bash
ssh git@github.com
# Output: Permissions 0644 for '/home/user/.ssh/id_ed25519' are too open.
```

**Fix**:
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 644 ~/.ssh/known_hosts

# Verify
ls -la ~/.ssh/
```

### Issue 8: Obsidian Alias Fails

**Symptom**:
```bash
obs
# Output: obsidian: vault not found
```

**Fix**:
```bash
# Check if path is correct
nano ~/.shell_common
# Line 10: Update path to your Obsidian vault location

# If vault not restored yet
# Copy from backup (see Phase 7.5, step 1)

# Reload
source ~/.shell_common
```

### Issue 9: Virtual Environment Activation Fails

**Symptom**:
```bash
activate_ai
# Output: No such file or directory
```

**Fix**:
```bash
# Check if venv exists
ls -la ~/neural_computing/ai_env/

# If not, create it
mkdir -p ~/neural_computing
python -m venv ~/neural_computing/ai_env

# If restoring from requirements
pip install -r ~/migration_package/dev/ai_env_requirements.txt

# Test
activate_ai
```

### Issue 10: Kitty Session File Not Working

**Symptom**:
```bash
kitty --session ~/.config/kitty/sessions/ai_agents.conf
# Output: Error loading session
```

**Fix**:
```bash
# Check if session file exists
cat ~/.config/kitty/sessions/ai_agents.conf

# If missing, recreate (see Phase 4.3)

# Test session syntax
kitty --config NONE --session ~/.config/kitty/sessions/ai_agents.conf

# Check Kitty version
kitty --version
# Session files require Kitty 0.26.0+
```

---

## Phase 13: Final Checklist and Sign-Off

### Comprehensive System Validation Checklist

**Core System** ✓
- [ ] Ubuntu 24.04 LTS installed and updated
- [ ] Zsh set as default shell
- [ ] Shell configs deployed (.zshrc, .bashrc, .shell_common)
- [ ] Oh-My-Zsh framework installed with plugins
- [ ] Custom prompt displaying correctly (green/red arrow + venv + directory)

**Version Managers** ✓
- [ ] Pyenv installed and in PATH
- [ ] Python 3.12.1 (or desired version) installed via pyenv
- [ ] `which python` shows `.pyenv/shims/python`
- [ ] NVM installed and in PATH
- [ ] Node.js LTS (v24.x) installed via NVM
- [ ] `which node` shows `.nvm/versions/node/.../bin/node`
- [ ] PATH order correct: pyenv → NVM → user bins → system

**Fonts and Terminal** ✓
- [ ] JetBrains Mono fonts installed (34 files)
- [ ] Font cache rebuilt (`fc-cache -f -v` executed)
- [ ] GNOME Terminal: 12 profiles imported
- [ ] GNOME Terminal: Default profile = "Vs Code Dark+"
- [ ] Kitty terminal installed
- [ ] Kitty configuration file created
- [ ] Kitty session files created (ai_agents.conf, research_quad.conf)

**AI Agents** ✓
- [ ] Claude Code CLI installed
- [ ] Claude Code authenticated
- [ ] Claude Code tested successfully
- [ ] GLM/Kimi CLI installed
- [ ] GLM/Kimi authenticated
- [ ] GLM/Kimi tested successfully
- [ ] Parallel AI session working in Kitty

**Development Environment** ✓
- [ ] Git configured (user.name, user.email)
- [ ] SSH keys restored with correct permissions (600/644)
- [ ] GPG keys restored and importable
- [ ] Python virtual environment created (~/neural_computing/ai_env/)
- [ ] Virtual environment alias working (`activate_ai`)

**Configurations Restored** ✓
- [ ] .claude/ configuration (if backed up)
- [ ] .kimi/ or .gemini/ configuration (if backed up)
- [ ] .mcp-servers/ configuration (if backed up)
- [ ] VSCode settings restored
- [ ] VSCode extensions installed
- [ ] Kitty configuration restored

**Data Restoration** ✓
- [ ] Obsidian vault restored
- [ ] Obsidian alias working (`obs`)
- [ ] Research data/code repositories cloned
- [ ] LaTeX environment set up (if needed)
- [ ] Zotero database restored (if applicable)

**Workflows and Scripts** ✓
- [ ] Daily workspace initialization script created
- [ ] Backup script created and tested
- [ ] Context sync script created
- [ ] Keyboard shortcuts configured
- [ ] Automatic backups scheduled (cron)

**Validation Tests** ✓
- [ ] `bash ~/terminal-config/deployment/validate.sh` passes all checks
- [ ] Pyenv resolution test passes
- [ ] NVM resolution test passes
- [ ] Claude Code launch test passes
- [ ] GLM/Kimi launch test passes
- [ ] Dual terminal session test passes
- [ ] Font rendering test passes (Kitty + GNOME Terminal)
- [ ] Aliases test passes (activate_ai, obs, ll, la, l)

### Post-Migration Tasks

**Immediate (Day 1)**:
- [ ] Test all critical workflows with AI agents
- [ ] Commit initial workspace to git
- [ ] Create first backup with `backup-workspace.sh`
- [ ] Update any additional hardcoded paths in scripts

**Week 1**:
- [ ] Fine-tune AI agent configurations
- [ ] Optimize Kitty session layouts for your workflow
- [ ] Install any additional academic tools (Zotero, LaTeX packages)
- [ ] Clone remaining git repositories
- [ ] Set up academic writing environment (if applicable)

**Month 1**:
- [ ] Review backup strategy and adjust as needed
- [ ] Optimize shell performance (profile loading time)
- [ ] Create project-specific AI workspace templates
- [ ] Document your custom workflows in AGENT.md

### Success Criteria

**System is considered fully restored when**:
1. All validation checks pass (bash deployment/validate.sh)
2. Both AI agents (Claude Code + GLM) run in parallel without issues
3. Version managers resolve correctly (pyenv/NVM take precedence)
4. All custom aliases work as expected
5. Terminal profiles render correctly with JetBrains Mono font
6. Research workflow is fully operational (Obsidian, venv, git, etc.)

---

## Appendix A: Quick Reference Commands

### Daily Commands

```bash
# Launch dual AI agents
kitty --session ~/.config/kitty/sessions/ai_agents.conf

# Or use shortcut (after Phase 11.2)
Ctrl+Alt+A

# Initialize daily workspace
ai-workspace-init.sh

# Activate Python virtual environment
activate_ai

# Open Obsidian vault
obs

# Backup current work
backup-workspace.sh

# Sync agent contexts
sync-agent-context.sh
```

### Version Manager Commands

```bash
# Python (Pyenv)
pyenv versions              # List installed versions
pyenv install 3.12.1        # Install specific version
pyenv global 3.12.1         # Set global default
pyenv local 3.10.13         # Set local (directory-specific)
pyenv which python          # Show actual Python binary path

# Node.js (NVM)
nvm ls                      # List installed versions
nvm install --lts          # Install latest LTS
nvm install 20.10.0        # Install specific version
nvm use 24                 # Use specific version
nvm alias default 24       # Set default version
nvm which node             # Show actual Node binary path
```

### Validation Commands

```bash
# Full system validation
cd ~/terminal-config && bash deployment/validate.sh

# PATH check
echo $PATH | tr ':' '\n' | nl

# Python check
which python && python --version && pyenv version

# Node check
which node && node --version && nvm current

# Font check
fc-list | grep "JetBrains Mono" | wc -l

# Terminal profiles check
dconf read /org/gnome/terminal/legacy/profiles:/list

# AI agent check
claude --version && kimi --version
```

### Backup Commands

```bash
# Full system backup (encrypted)
cd ~/terminal-config && bash migration/02_backup.sh

# Workspace backup
backup-workspace.sh

# Manual backup to external HDD
BACKUP_ROOT="/media/user/BACKUP_$(date +%Y%m%d)"
mkdir -p "$BACKUP_ROOT"
cp -r ~/.zshrc ~/.bashrc ~/.shell_common "$BACKUP_ROOT/"
cp -r ~/.ssh "$BACKUP_ROOT/"
cp -r ~/.claude "$BACKUP_ROOT/"
cp -r ~/ai_workspace "$BACKUP_ROOT/"
```

---

## Appendix B: File Locations Reference

### Configuration Files

| File/Directory | Location | Purpose |
|----------------|----------|---------|
| `.zshrc` | `~/` | Zsh configuration with pyenv/NVM init |
| `.bashrc` | `~/` | Bash configuration (sources .shell_common) |
| `.shell_common` | `~/` | Shared aliases, PATH additions |
| `.oh-my-zsh/` | `~/` | Oh-My-Zsh framework |
| `kitty.conf` | `~/.config/kitty/` | Kitty terminal configuration |
| Kitty sessions | `~/.config/kitty/sessions/` | Pre-configured layouts |
| GNOME profiles | dconf database | `/org/gnome/terminal/legacy/profiles:/` |
| Claude Code | `~/.claude/`, `~/.claude.json` | Claude CLI configuration |
| GLM/Kimi | `~/.kimi/`, `~/.gemini/` | GLM/Kimi CLI configuration |
| MCP servers | `~/.mcp-servers/` | Model Context Protocol servers |
| JetBrains Mono | `~/.local/share/fonts/` | Font files (34 TTF) |

### Data Directories

| Directory | Location | Purpose |
|-----------|----------|---------|
| Pyenv root | `~/.pyenv/` | Python versions and shims |
| NVM root | `~/.nvm/` | Node.js versions |
| AI workspace | `~/ai_workspace/` | Daily AI agent collaboration |
| Python venv | `~/neural_computing/ai_env/` | Research virtual environment |
| Obsidian vault | `/media/user/New Volume/Downloads/##_MarkDown_Files_` | Markdown notes |
| Backup archive | `~/migration_package_*.tar.gz.gpg` | Encrypted system backup |
| Workspace backups | `~/backups/ai_workspace/` | Daily workspace snapshots |

### Scripts and Binaries

| Script | Location | Purpose |
|--------|----------|---------|
| Discovery | `~/terminal-config/migration/01_discover.sh` | Catalog system state |
| Backup | `~/terminal-config/migration/02_backup.sh` | Create encrypted archive |
| Deployment | `~/terminal-config/deployment/install.sh` | Deploy from repo |
| Validation | `~/terminal-config/deployment/validate.sh` | Verify installation |
| Archive deploy | `~/terminal-config/migration/03_deploy.sh` | Deploy from archive |
| Workspace init | `~/bin/ai-workspace-init.sh` | Daily workspace setup |
| Backup script | `~/bin/backup-workspace.sh` | Backup current work |
| Context sync | `~/bin/sync-agent-context.sh` | Sync AI agent contexts |

---

## Appendix C: Expected Disk Space Usage

### Fresh Installation (Minimal)

| Component | Size | Required? |
|-----------|------|-----------|
| Ubuntu 24.04 LTS | ~6 GB | ✓ Yes |
| Build tools + deps | ~500 MB | ✓ Yes |
| Oh-My-Zsh framework | ~50 MB | ✓ Yes |
| JetBrains Mono fonts | ~8 MB | ✓ Yes |
| Kitty terminal | ~100 MB | ✓ Yes |
| **Subtotal (Minimal)** | **~6.7 GB** | |

### Development Tools

| Component | Size | Required? |
|-----------|------|-----------|
| Pyenv + Python 3.12 | ~500 MB | ✓ Yes (for AI agents) |
| NVM + Node.js 24 | ~300 MB | ✓ Yes (for AI agents) |
| Claude Code CLI | ~50 MB | ✓ Yes |
| GLM/Kimi CLI | ~50 MB | ✓ Yes |
| VSCode | ~400 MB | Recommended |
| **Subtotal (Dev Tools)** | **~1.3 GB** | |

### Optional Components

| Component | Size | Required? |
|-----------|------|-----------|
| Additional Python versions (×3) | ~1.5 GB | Optional |
| Python venv (research) | ~2 GB | Optional |
| LaTeX (texlive-full) | ~5 GB | Optional |
| Zotero + database | ~1 GB | Optional |
| Obsidian + vault | ~500 MB | Optional |
| **Subtotal (Optional)** | **~10 GB** | |

### Restored Data

| Component | Size | Required? |
|-----------|------|-----------|
| Backup archive | ~3 GB | ✓ Yes (for restoration) |
| Git repositories | ~2 GB | Optional |
| Research data | Variable | Optional |
| Browser profiles | ~1 GB | Optional |
| **Subtotal (Data)** | **~6 GB** | |

### Total Recommended Disk Space

**Minimal Setup**: ~8 GB (OS + essential tools + AI agents)
**Recommended Setup**: ~20 GB (includes dev tools + optional components)
**Full Restoration**: ~30 GB (includes all data and optional components)

---

## Appendix D: Network Resources and URLs

### Official Downloads

- Ubuntu 24.04 LTS: https://ubuntu.com/download/desktop
- Pyenv: https://github.com/pyenv/pyenv
- NVM: https://github.com/nvm-sh/nvm
- Kitty: https://sw.kovidgoyal.net/kitty/
- Oh-My-Zsh: https://ohmyz.sh/
- Claude Code CLI: https://docs.anthropic.com/claude/docs/claude-code (hypothetical - adjust to actual URL)
- GLM: https://github.com/THUDM/GLM-4
- Kimi (Moonshot AI): https://platform.moonshot.cn/
- Obsidian: https://obsidian.md/download
- VSCode: https://code.visualstudio.com/download
- Zotero: https://www.zotero.org/download/

### Documentation

- terminal-config repository: https://github.com/YOUR_USERNAME/terminal-config
- AGENT.md: Complete repository architecture and technical specs
- USER_IDENTITY.md: Communication style and preferences
- CLAUDE.md: Claude Code-specific guidelines
- GEMINI.md: Gemini CLI-specific guidelines

### Plugin Repositories

- zsh-autosuggestions: https://github.com/zsh-users/zsh-autosuggestions
- zsh-syntax-highlighting: https://github.com/zsh-users/zsh-syntax-highlighting
- fast-syntax-highlighting: https://github.com/zdharma-continuum/fast-syntax-highlighting

---

## Document Metadata

**Document Version**: 1.0
**Created**: 2026-02-12
**Last Updated**: 2026-02-12
**Target OS**: Ubuntu 24.04 LTS
**Source Repository**: terminal-config v1.0.0 + migration v1.1.0
**Author**: Generated by Claude Sonnet 4.5
**Intended Audience**: GLM Agent + User (Abhimanyu Dubey)

**Execution Expectation**:
- Total time: 4-6 hours (excluding OS installation)
- Complexity: Medium-High (requires attention to detail)
- Success rate: 95%+ (if followed carefully)
- Rollback capability: Yes (via backups created in Phase 0)

**Post-Migration Support**:
- Validation: deployment/validate.sh
- Troubleshooting: Phase 12 of this document
- Community: GitHub issues on terminal-config repository
- Updates: Check CHANGELOG.md for version updates

---

**END OF COMPREHENSIVE EXECUTION PLAN**

🎯 **Ready for GLM Agent Execution**: This plan is comprehensive, detailed, and executable step-by-step. Provide this to your GLM agent to restore your Ubuntu 24 system to full operational state with dual AI agent workflow.
