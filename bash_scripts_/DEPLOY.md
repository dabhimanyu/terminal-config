# Terminal Environment Deployment Guide

Complete deployment instructions for replicating the terminal configuration on any Ubuntu-based Linux machine.

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Deployment Steps](#deployment-steps)
4. [Post-Deployment Verification](#post-deployment-verification)
5. [Troubleshooting](#troubleshooting)
6. [Optional Enhancements](#optional-enhancements)

---

## Overview

This deployment package contains:
- **Shell Configurations**: `.zshrc`, `.bashrc`, `.shell_common` (Single Source of Truth)
- **Oh-My-Zsh Framework**: Complete with themes
- **JetBrains Mono Fonts**: Full font family (50+ variants)
- **GNOME Terminal Profiles**: All custom profiles with colors and settings
- **Plugins**: Auto-suggestions and syntax highlighting (cloned during deployment)

**Estimated Time**: 5-10 minutes  
**Requires**: Internet connection, sudo access

---

## Prerequisites

### System Requirements

- **OS**: Ubuntu 20.04+ or compatible Debian-based distribution
- **Terminal**: GNOME Terminal 3.36+
- **Desktop Environment**: GNOME 3.36+

### Required Packages

The deployment script will automatically install:
- `zsh` - Z Shell
- `git` - Version control
- `curl`, `wget` - Download utilities
- `unzip` - Archive extraction
- `dconf-cli` - GNOME configuration tool
- `fontconfig` - Font management

---

## Deployment Steps

### Step 1: Clone Repository

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/terminal-config.git
cd terminal-config
```

**Verification:**
```bash
ls -la
# Should show: shell_configs/, oh-my-zsh/, fonts/, dconf/, deployment/, metadata/
```

---

### Step 2: Run Deployment Script

```bash
# Make script executable (if needed)
chmod +x deployment/install.sh

# Run deployment
bash deployment/install.sh
```

**What This Does:**
1. Installs prerequisites (zsh, git, etc.)
2. Deploys shell configuration files (backs up existing)
3. Installs Oh-My-Zsh framework
4. Clones plugins from GitHub
5. Installs JetBrains Mono fonts
6. Imports all GNOME Terminal profiles
7. Sets Zsh as default shell

**Expected Output:**
```
════════════════════════════════════════════════════════════════
Terminal Environment Deployment
════════════════════════════════════════════════════════════════

▶ Phase 1: Installing prerequisites
→ All prerequisites satisfied
✓ ...

▶ Phase 8: Checking path-dependent aliases
⚠ VERIFY these paths match your system
...

════════════════════════════════════════════════════════════════
✓ Deployment Complete
════════════════════════════════════════════════════════════════
```

---

### Step 3: Log Out and Log Back In

**CRITICAL**: The shell change only takes effect after a new login session.

```bash
# Log out via GUI or command:
gnome-session-quit --logout --no-prompt
```

**Alternative**: Reboot the system
```bash
sudo reboot
```

---

### Step 4: Verify Installation

After logging back in, open a new terminal and run:

```bash
# Navigate to repository
cd ~/terminal-config

# Run validation script
bash deployment/validate.sh
```

**Expected Output:**
```
════════════════════════════════════════════════════════════════
Terminal Environment Validation
════════════════════════════════════════════════════════════════

1. Default Shell
✓ Zsh is default shell
ℹ Zsh version: zsh 5.8 (x86_64-ubuntu-linux-gnu)

...

════════════════════════════════════════════════════════════════
✓ ALL CHECKS PASSED
════════════════════════════════════════════════════════════════
```

---

### Step 5: Update Path-Dependent Aliases

The `.shell_common` file may contain paths specific to the source machine.

```bash
# Edit .shell_common
nano ~/.shell_common
```

**Update the following if paths differ:**

```bash
# Example: Obsidian vault path
alias obs='obsidian vault open "/your/actual/path/to/vault"'

# Example: Python virtual environment
alias activate_ai='source /your/actual/path/to/venv/bin/activate'
```

**Save and reload:**
```bash
source ~/.shell_common
```

---

## Post-Deployment Verification

### Visual Checks

1. **Prompt Appearance**
   - Should show colored prompt with `➜` symbol
   - Current directory in cyan
   - Git branch info (if in git repo)

2. **Syntax Highlighting**
   - Valid commands: green
   - Invalid commands: red
   - Strings: yellow
   - Numbers: blue

3. **Autosuggestions**
   - Start typing a command
   - Should see gray text suggesting completion
   - Press `→` (right arrow) to accept

4. **Font Rendering**
   - Characters should be crisp and monospaced
   - Ligatures should render (e.g., `!=`, `=>`, `->`)

### Functional Tests

```bash
# Test 1: Oh-My-Zsh loaded
echo $ZSH
# Expected: /home/username/.oh-my-zsh

# Test 2: Plugins active
type _zsh_autosuggest_start
# Expected: _zsh_autosuggest_start is a shell function...

# Test 3: Font installed
fc-list | grep -i "JetBrains Mono" | wc -l
# Expected: 40+ (number of font variants)

# Test 4: Aliases work
alias | grep obs
# Expected: obs='obsidian vault open "..."'
```

---

## Troubleshooting

### Issue 1: Shell Not Changed to Zsh

**Symptoms:**
- After logging back in, still using Bash
- `echo $SHELL` shows `/bin/bash`

**Solution:**
```bash
# Manually change shell
chsh -s $(which zsh)

# Verify
which zsh
# Expected: /usr/bin/zsh or /bin/zsh

# Log out and log back in
```

---

### Issue 2: Plugins Not Working

**Symptoms:**
- No syntax highlighting
- No autosuggestions
- Commands appear in white/default color

**Solution:**
```bash
# Check plugin directories exist
ls ~/.oh-my-zsh/custom/plugins/

# If missing, clone manually:
PLUGIN_DIR="$HOME/.oh-my-zsh/custom/plugins"

git clone https://github.com/zsh-users/zsh-autosuggestions.git \
    $PLUGIN_DIR/zsh-autosuggestions

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    $PLUGIN_DIR/zsh-syntax-highlighting

# Reload configuration
source ~/.zshrc
```

---

### Issue 3: Font Not Applied

**Symptoms:**
- Terminal uses Monospace or default font
- No ligatures rendering
- Font looks different from expected

**Solution:**

```bash
# 1. Verify fonts installed
fc-list | grep "JetBrains Mono"
# Should list multiple variants

# 2. If no output, reinstall fonts:
cd /tmp
wget https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip
unzip JetBrainsMono-2.304.zip -d jetbrains
cp jetbrains/fonts/ttf/*.ttf ~/.local/share/fonts/
fc-cache -f -v

# 3. Enable font in Terminal
# GUI: Terminal → Preferences → [Profile] → Text
# Check "Custom font"
# Select: "JetBrains Mono Regular 11" (or 12)
```

**Command-line method:**
```bash
# Get default profile UUID
DEFAULT_UUID=$(dconf read /org/gnome/terminal/legacy/profiles:/default | tr -d "'")

# Set font
dconf write "/org/gnome/terminal/legacy/profiles:/:$DEFAULT_UUID/use-system-font" "false"
dconf write "/org/gnome/terminal/legacy/profiles:/:$DEFAULT_UUID/font" "'JetBrains Mono 12'"
```

---

### Issue 4: Terminal Colors Wrong

**Symptoms:**
- Black on white instead of dark theme
- No color scheme applied

**Solution:**

```bash
# Check if profile imported
dconf list /org/gnome/terminal/legacy/profiles:/ | grep ':'

# If empty, re-import profiles
cd ~/terminal-config
for profile in dconf/profile_*.dconf; do
    UUID=$(uuidgen)
    dconf load "/org/gnome/terminal/legacy/profiles:/:$UUID/" < "$profile"
done
```

---

### Issue 5: Aliases Not Working

**Symptoms:**
- `obs` command not found
- `activate_ai` fails

**Solution:**

```bash
# 1. Check if .shell_common is sourced in .zshrc
grep "shell_common" ~/.zshrc

# If missing, add to ~/.zshrc:
echo '[ -f ~/.shell_common ] && source ~/.shell_common' >> ~/.zshrc

# 2. Verify paths in aliases
cat ~/.shell_common | grep "^alias"

# 3. Update paths to match your system
nano ~/.shell_common

# 4. Reload
source ~/.shell_common
```

---

## Optional Enhancements

### Install Fira Code (Alternative Font with Ligatures)

```bash
sudo apt install fonts-firacode
fc-cache -f -v

# Enable in Terminal:
# Preferences → Text → Select "Fira Code Regular 11"
```

---

### Install Additional Fonts

```bash
# Hack font
sudo apt install fonts-hack

# Source Code Pro
sudo apt install fonts-source-code-pro

# Cascadia Code
wget https://github.com/microsoft/cascadia-code/releases/download/v2111.01/CascadiaCode-2111.01.zip
unzip CascadiaCode-2111.01.zip -d cascadia
cp cascadia/ttf/*.ttf ~/.local/share/fonts/
fc-cache -f -v
```

---

### Add More Oh-My-Zsh Plugins

```bash
# Example: Add command time plugin
cd ~/.oh-my-zsh/custom/plugins
git clone https://github.com/popstas/zsh-command-time.git command-time

# Edit .zshrc and add to plugins array:
# plugins=(git python pip virtualenv ... command-time)

# Reload
source ~/.zshrc
```

**Popular plugins:**
- `command-time` - Shows execution time for long commands
- `z` - Jump to frequently used directories
- `extract` - Universal archive extraction
- `docker` - Docker completion and aliases
- `kubectl` - Kubernetes completion

---

### Customize Prompt (Powerlevel10k)

```bash
# Install Powerlevel10k theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    ~/.oh-my-zsh/custom/themes/powerlevel10k

# Set theme in .zshrc
sed -i 's/ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc

# Configure
p10k configure

# Reload
source ~/.zshrc
```

---

## Advanced Configuration

### Create Profile Variants

You can create additional profiles for different use cases:

```bash
# Duplicate current profile
UUID=$(uuidgen)
dconf dump /org/gnome/terminal/legacy/profiles:/:$(dconf read /org/gnome/terminal/legacy/profiles:/default | tr -d "'")/ | \
    dconf load "/org/gnome/terminal/legacy/profiles:/:$UUID/"

# Modify name
dconf write "/org/gnome/terminal/legacy/profiles:/:$UUID/visible-name" "'My Custom Profile'"
```

---

### Sync Across Machines

To keep terminal config synchronized across multiple machines:

```bash
# On machine 1: Commit changes
cd ~/terminal-config
cp ~/.zshrc shell_configs/
cp ~/.shell_common shell_configs/
git add .
git commit -m "Update configuration"
git push

# On machine 2: Pull updates
cd ~/terminal-config
git pull
cp shell_configs/.zshrc ~/
cp shell_configs/.shell_common ~/
source ~/.zshrc
```

---

## Support and Maintenance

### Update Oh-My-Zsh

```bash
omz update
```

### Update Plugins

```bash
cd ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git pull

cd ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git pull
```

### Backup Current Configuration

```bash
# Create backup
tar -czf ~/terminal_backup_$(date +%Y%m%d).tar.gz \
    ~/.zshrc \
    ~/.bashrc \
    ~/.shell_common \
    ~/.oh-my-zsh

# Export current profiles
dconf dump /org/gnome/terminal/ > ~/terminal_profiles_$(date +%Y%m%d).dconf
```

---

## Uninstallation

If you need to revert to previous configuration:

```bash
# Restore shell
chsh -s /bin/bash

# Restore config files (if backups exist)
mv ~/.zshrc.pre-migration* ~/.zshrc
mv ~/.bashrc.pre-migration* ~/.bashrc
mv ~/.shell_common.pre-migration* ~/.shell_common

# Remove Oh-My-Zsh
rm -rf ~/.oh-my-zsh

# Restore terminal profiles
dconf load /org/gnome/terminal/ < ~/gnome_terminal_backup_*.dconf

# Remove fonts (optional)
rm ~/.local/share/fonts/JetBrainsMono*.ttf
fc-cache -f -v
```

---

## Questions and Feedback

For issues or improvements, refer to:
- Repository: https://github.com/YOUR_USERNAME/terminal-config
- Validation script: `bash deployment/validate.sh`
- This guide: `deployment/DEPLOY.md`

---

**Last Updated**: 2026-01-12  
**Version**: 1.0
