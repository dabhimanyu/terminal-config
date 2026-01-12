# Terminal Configuration Migration - Master Execution Guide

This document provides step-by-step instructions for the complete migration process from source machine to target machine.

---

## Table of Contents

1. [Overview](#overview)
2. [Source Machine: Extraction](#source-machine-extraction)
3. [Source Machine: Git Repository Setup](#source-machine-git-repository-setup)
4. [GitHub: Repository Creation](#github-repository-creation)
5. [Target Machine: Deployment](#target-machine-deployment)
6. [Verification](#verification)

---

## Overview

### Migration Architecture

```
SOURCE MACHINE                    GITHUB                    TARGET MACHINE
┌──────────────┐                ┌────────┐                ┌──────────────┐
│              │                │        │                │              │
│  Extract     │  ──────────>   │  Git   │  ──────────>   │  Deploy      │
│  Config      │                │  Repo  │                │  Config      │
│              │                │        │                │              │
└──────────────┘                └────────┘                └──────────────┘
     Scripts:                                                  Scripts:
   - 00_preflight_check.sh                                  - install.sh
   - 01_extract_config.sh                                   - validate.sh
   - 02_setup_git_repo.sh
   - 03_add_deployment_scripts.sh
```

### Component Summary

**What Gets Migrated:**
- ✓ Shell configuration files (.zshrc, .bashrc, .shell_common)
- ✓ Oh-My-Zsh framework (themes, plugins re-cloned)
- ✓ JetBrains Mono fonts (50+ .ttf files)
- ✓ ALL GNOME Terminal profiles (colors, fonts, palettes)

**What Does NOT Get Migrated:**
- ✗ Virtual environments (recreate on target)
- ✗ Path-specific data (update manually)

---

## Source Machine: Extraction

### Step 1: Download Extraction Scripts

Download all scripts to `~/neural_computing/` or any working directory.

**Scripts Required:**
- `00_preflight_check.sh`
- `01_extract_config.sh`
- `02_setup_git_repo.sh`
- `03_add_deployment_scripts.sh`

**Make Executable:**
```bash
cd ~/neural_computing/
chmod +x 00_preflight_check.sh
chmod +x 01_extract_config.sh
chmod +x 02_setup_git_repo.sh
chmod +x 03_add_deployment_scripts.sh
```

---

### Step 2: Run Pre-Flight Check

**Purpose:** Verify current system state before extraction.

```bash
bash 00_preflight_check.sh
```

**Expected Output:**
```
════════════════════════════════════════════════════════════════
Terminal Environment Pre-Flight Validation
════════════════════════════════════════════════════════════════

1. Font Installation Status
   Detected JetBrains Mono variants: 50+
   ✓ Fonts present

2. Font File Locations
   Total JetBrains Mono .ttf files: 50+
   ...

3. GNOME Terminal Profiles
   Default Profile UUID: 934a1a08-5d50-4a6e-aa06-f68537fb48d9
   Profile Name: Vs Code Dark+
   ...
   ✓ Total profiles detected: 11

...

✓ Pre-Flight Validation Complete
```

**Action:**
- Review output for any ✗ (failures)
- Ensure fonts, profiles, and configs are present
- If failures exist, address before proceeding

---

### Step 3: Extract Configuration

**Purpose:** Create migration package with all components.

```bash
bash 01_extract_config.sh
```

**Expected Output:**
```
▶ Initializing migration workspace
→ Creating directory structure: /home/user/terminal_migration_20260112_HHMMSS

▶ Phase 1: Extracting shell configuration files
→ ✓ Extracted .zshrc
→ ✓ Extracted .bashrc
→ ✓ Extracted .shell_common

▶ Phase 2: Extracting Oh-My-Zsh framework
→ ✓ Framework extracted

▶ Phase 3: Extracting JetBrains Mono fonts
→ Found 50 font files
→ ✓ Extracted 50 font files

▶ Phase 4: Extracting ALL GNOME Terminal profiles
→ Default profile UUID: 934a1a08-5d50-4a6e-aa06-f68537fb48d9
→ [1] Exported: "Vs Code Dark+" (DEFAULT)
→ [2] Exported: "Profile 2"
...
→ ✓ Total profiles exported: 11

...

════════════════════════════════════════════════════════════════
✓ Migration Package Created Successfully
════════════════════════════════════════════════════════════════

PACKAGE DETAILS:
  Archive: /home/user/terminal_backup_20260112_HHMMSS.tar.gz
  Workspace: /home/user/terminal_migration_20260112_HHMMSS
  Size: 12M

NEXT STEPS:
  1. Verify tarball integrity...
```

**Verification:**
```bash
# List tarball contents
tar -tzf ~/terminal_backup_*.tar.gz | head -30

# Should show:
# terminal_migration_TIMESTAMP/
# terminal_migration_TIMESTAMP/shell_configs/
# terminal_migration_TIMESTAMP/fonts/
# terminal_migration_TIMESTAMP/dconf/
# terminal_migration_TIMESTAMP/metadata/
```

---

## Source Machine: Git Repository Setup

### Step 4: Initialize Git Repository

**Purpose:** Create version-controlled repository from extracted config.

```bash
bash 02_setup_git_repo.sh
```

**Interactive Prompts:**
```
→ Creating Git repository structure
⚠ Repository directory already exists: /home/user/terminal-config
   Delete and recreate? (y/n):
```
- First run: No prompt (directory doesn't exist)
- Subsequent runs: Choose 'y' to recreate

**Git Configuration (if not already set):**
```
⚠ Git user.name not configured
   Enter your name: Your Name
⚠ Git user.email not configured
   Enter your email: your.email@example.com
```

**Expected Output:**
```
▶ Copying migration contents to repository
→ Copying shell configuration files...
→ Copying Oh-My-Zsh framework...
→ Copying JetBrains Mono fonts...
→ ✓ Copied 50 font files to repository
→ Copying GNOME Terminal profiles...
→ ✓ Copied 11 profile files

...

▶ Creating initial commit
→ ✓ Initial commit created

════════════════════════════════════════════════════════════════
✓ Git Repository Setup Complete
════════════════════════════════════════════════════════════════

Repository location: /home/user/terminal-config
```

**Verification:**
```bash
cd ~/terminal-config
ls -la

# Expected structure:
# shell_configs/
# oh-my-zsh/
# fonts/
# dconf/
# metadata/
# deployment/  (empty at this stage)
# README.md
# MANIFEST.md
# .gitignore
# .git/
```

---

### Step 5: Add Deployment Scripts to Repository

**Purpose:** Add automation scripts for target machine.

```bash
bash 03_add_deployment_scripts.sh
```

**Expected Output:**
```
▶ Locating deployment scripts
→ Script source directory: /home/user/neural_computing
→ ✓ All deployment files located

▶ Copying deployment scripts to repository
→ ✓ Copied install.sh
→ ✓ Copied validate.sh
→ ✓ Copied DEPLOY.md
→ ✓ Created quick_start.sh

▶ Committing deployment scripts to Git
→ ✓ Changes committed

════════════════════════════════════════════════════════════════
✓ Deployment Scripts Added to Repository
════════════════════════════════════════════════════════════════
```

**Verification:**
```bash
cd ~/terminal-config
ls -la deployment/

# Expected files:
# install.sh
# validate.sh
# DEPLOY.md
# quick_start.sh
```

---

## GitHub: Repository Creation

### Step 6: Create GitHub Repository

**Option A: Web Interface**

1. Go to https://github.com/new
2. Repository name: `terminal-config`
3. Description: "Terminal configuration for research environment"
4. Visibility: Public (or Private)
5. **Do NOT** initialize with README, .gitignore, or license
6. Click "Create repository"

**Option B: GitHub CLI (if installed)**
```bash
gh repo create terminal-config --public --source=~/terminal-config
```

---

### Step 7: Push to GitHub

```bash
cd ~/terminal-config

# Add remote (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/terminal-config.git

# Rename branch to main (if needed)
git branch -M main

# Push
git push -u origin main
```

**Expected Output:**
```
Enumerating objects: 150, done.
Counting objects: 100% (150/150), done.
Delta compression using up to 8 threads
Compressing objects: 100% (120/120), done.
Writing objects: 100% (150/150), 12.5 MiB | 2.5 MiB/s, done.
Total 150 (delta 20), reused 0 (delta 0)
To https://github.com/YOUR_USERNAME/terminal-config.git
 * [new branch]      main -> main
Branch 'main' set up to track remote branch 'main' from 'origin'.
```

**Verification:**
- Visit https://github.com/YOUR_USERNAME/terminal-config
- Should see README.md displayed
- Verify `fonts/` directory contains .ttf files
- Verify `deployment/` directory contains scripts

---

## Target Machine: Deployment

### Step 8: Clone Repository on Target Machine

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/terminal-config.git

# Navigate to repository
cd terminal-config

# Verify contents
ls -la
```

---

### Step 9: Run Deployment Script

**Method 1: Standard Deployment**
```bash
bash deployment/install.sh
```

**Method 2: Quick Start (Interactive)**
```bash
bash deployment/quick_start.sh
```

**Expected Output:**
```
════════════════════════════════════════════════════════════════
Terminal Environment Deployment
════════════════════════════════════════════════════════════════

Target User: newuser
Target Hostname: new-machine
Target OS: Ubuntu 22.04.3 LTS

▶ Phase 1: Installing prerequisites
→ ✓ All prerequisites satisfied

▶ Phase 2: Deploying shell configuration files
→ ✓ Deployed .zshrc
→ ✓ Deployed .bashrc
→ ✓ Deployed .shell_common

▶ Phase 3: Deploying Oh-My-Zsh framework
→ ✓ Framework deployed

▶ Phase 4: Installing plugins from upstream
→ Cloning zsh-autosuggestions...
→ ✓ zsh-autosuggestions installed
→ Cloning zsh-syntax-highlighting...
→ ✓ zsh-syntax-highlighting installed

▶ Phase 5: Installing JetBrains Mono fonts
→ Fonts found in repository, copying...
→ Copied 50 font files from repository
→ Rebuilding font cache...
→ ✓ Font verification: 50 variants detected

▶ Phase 6: Importing GNOME Terminal profiles
→ Existing profiles backed up to: ~/gnome_terminal_backup_20260112.dconf
→ Original default profile UUID: 934a1a08-5d50-4a6e-aa06-f68537fb48d9
→ [1] Imported: "Vs Code Dark+" (will be set as DEFAULT)
→ [2] Imported: "Profile 2"
...
→ ✓ Profile list updated with 11 profiles
→ ✓ Default profile set to: "Vs Code Dark+"

▶ Phase 7: Setting Zsh as default shell
→ Current shell: bash
→ Changing default shell to Zsh...
→ ✓ Default shell changed to Zsh
⚠ You MUST log out and log back in for this to take effect

▶ Phase 8: Checking path-dependent aliases
→ Path-dependent aliases detected in .shell_common:

   alias activate_ai='source ~/neural_computing/ai_env/bin/activate'
   alias obs='obsidian vault open "/media/user/New Volume/Downloads/##_MarkDown_Files_"'

⚠ VERIFY these paths match your system
⚠ Edit ~/.shell_common if paths differ

════════════════════════════════════════════════════════════════
✓ Deployment Complete
════════════════════════════════════════════════════════════════

CRITICAL POST-DEPLOYMENT ACTIONS:

1. LOG OUT AND LOG BACK IN (or reboot)
   This activates Zsh as your default shell

2. Open a new terminal window
   Verify prompt appearance and colors

3. Run validation script:
   bash ~/terminal-config/deployment/validate.sh

4. Update path-dependent aliases:
   nano ~/.shell_common
   (Update 'obs' alias and 'activate_ai' alias paths)
```

---

### Step 10: Log Out and Log Back In

**CRITICAL STEP - Do not skip**

```bash
# Method 1: GUI logout
gnome-session-quit --logout --no-prompt

# Method 2: Reboot
sudo reboot
```

After logging back in, you should see:
- Colored Zsh prompt with `➜` symbol
- Current directory in cyan
- Different visual appearance from Bash

---

## Verification

### Step 11: Run Validation Script

```bash
cd ~/terminal-config
bash deployment/validate.sh
```

**Expected Output:**
```
════════════════════════════════════════════════════════════════
Terminal Environment Validation
════════════════════════════════════════════════════════════════

1. Default Shell
✓ Zsh is default shell
ℹ Shell path: /usr/bin/zsh
ℹ Zsh version: zsh 5.8 (x86_64-ubuntu-linux-gnu)

2. Configuration Files
✓ .zshrc present (895 bytes)
✓ .bashrc present (3771 bytes)
✓ .shell_common present (723 bytes)
✓ .zshrc sources .shell_common

3. Oh-My-Zsh Framework
✓ Framework directory exists
✓ Core script present
✓ Themes directory present (148 themes)

4. Oh-My-Zsh Plugins
✓ Custom plugins directory exists
✓ zsh-autosuggestions installed
✓ zsh-syntax-highlighting installed
✓ Plugins enabled in .zshrc

5. JetBrains Mono Font
✓ Font installed (50 variants detected)
ℹ Sample variants:
     /home/newuser/.local/share/fonts/JetBrainsMono-Regular.ttf...
✓ Font files present in ~/.local/share/fonts (50 files)

6. GNOME Terminal Profiles
✓ Profiles detected (11 profiles)
✓ Default profile set: "Vs Code Dark+"
✓ Custom font enabled: JetBrains Mono 12
✓ Custom colors enabled

7. Path-Dependent Aliases
ℹ Detected 2 aliases in .shell_common

ℹ Manual verification required for these paths:
     alias activate_ai='source ~/neural_computing/ai_env/bin/activate'
     alias obs='obsidian vault open "/media/user/New Volume/..."'

⚠ Update paths in ~/.shell_common if they differ on this system

8. Zsh Functionality
✓ Running in Zsh (version: 5.8)
✓ Oh-My-Zsh loaded (ZSH=/home/newuser/.oh-my-zsh)

9. Environment Variables
✓ ~/.local/bin in PATH
ℹ ~/bin not in PATH (may not exist)

10. Backup Files
ℹ Found 3 backup files from migration:
     /home/newuser/.zshrc.pre-migration-20260112_150530
     /home/newuser/.bashrc.pre-migration-20260112_150530
     ...

ℹ These can be safely deleted after confirming everything works

════════════════════════════════════════════════════════════════
✓ ALL CHECKS PASSED
════════════════════════════════════════════════════════════════

Terminal environment successfully deployed!
```

**If Warnings Appear:**
- Review warning messages
- Most warnings are for manual verification (paths in aliases)
- Address any ✗ failures

---

### Step 12: Update Path-Dependent Aliases

```bash
# Edit .shell_common
nano ~/.shell_common

# Update paths to match target system:
# Example:
# OLD: alias obs='obsidian vault open "/media/user/New Volume/..."'
# NEW: alias obs='obsidian vault open "/home/newuser/Documents/Obsidian"'

# Save (Ctrl+O, Enter, Ctrl+X)

# Reload configuration
source ~/.shell_common
```

---

### Step 13: Visual and Functional Tests

**Visual Tests:**
1. Open new terminal → Should see colored prompt
2. Type a command (don't press Enter) → Should see syntax highlighting
3. Start typing a command you've used before → Should see gray suggestion
4. Check Terminal → Preferences → Text → Font should be "JetBrains Mono 12"

**Functional Tests:**
```bash
# Test 1: Zsh is active
echo $SHELL
# Expected: /usr/bin/zsh

# Test 2: Oh-My-Zsh loaded
echo $ZSH
# Expected: /home/username/.oh-my-zsh

# Test 3: Plugins active
type _zsh_autosuggest_start
# Expected: _zsh_autosuggest_start is a shell function...

# Test 4: Aliases work
alias | grep obs
# Expected: obs='obsidian vault open "..."'

# Test 5: Font installed
fc-list | grep "JetBrains Mono" | wc -l
# Expected: 40-50
```

---

## Summary Checklist

**Source Machine:**
- [x] Run `00_preflight_check.sh` → Verify current state
- [x] Run `01_extract_config.sh` → Create migration package
- [x] Run `02_setup_git_repo.sh` → Initialize Git repository
- [x] Run `03_add_deployment_scripts.sh` → Add deployment scripts
- [x] Create GitHub repository
- [x] Push to GitHub

**Target Machine:**
- [x] Clone repository from GitHub
- [x] Run `deployment/install.sh`
- [x] Log out and log back in
- [x] Run `deployment/validate.sh`
- [x] Update path-dependent aliases
- [x] Perform visual and functional tests

---

## Troubleshooting Quick Reference

| Issue | Solution |
|-------|----------|
| Shell not Zsh after login | `chsh -s $(which zsh)` → log out → log back in |
| No syntax highlighting | Verify plugins in `~/.oh-my-zsh/custom/plugins/` |
| Font not applied | Terminal → Preferences → Text → Select JetBrains Mono |
| Aliases not working | Check `~/.shell_common` is sourced in `~/.zshrc` |
| Profiles missing | Re-run profile import from `dconf/` directory |

Full troubleshooting guide: `deployment/DEPLOY.md`

---

## Context Window Utilization

**Estimated Remaining:** ~60-65%

**Breakdown:**
- System prompts: ~8,000 tokens
- User preferences: ~2,500 tokens
- Conversation history: ~30,000 tokens
- Documents created: ~35,000 tokens
- **Total consumed:** ~75,500 / 190,000 = **39.7% used**
- **Remaining:** **~114,500 tokens (~60.3%)**

---

**End of Master Execution Guide**
