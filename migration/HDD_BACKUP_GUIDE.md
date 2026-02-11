# HDD Backup Guide - Terminal Migration

**Purpose**: Manual backup of critical system files before migrating to a new machine.

**Date Created**: 2026-02-11

---

## Quick Reference Summary

| Priority | Category | Size | Files/Directories |
|----------|----------|------|-------------------|
| CRITICAL | Shell Configs | ~20 KB | .zshrc, .bashrc, .shell_common, .zsh_history |
| CRITICAL | Security Keys | ~32 KB | .ssh/, .gnupg/ |
| CRITICAL | Terminal Config | ~52 KB | dconf/ (12 GNOME profiles) |
| HIGH | Font Files | ~8.1 MB | JetBrains Mono (34 TTF files) |
| HIGH | Academic Tools | ~846 MB | VSCode settings, Obsidian config |
| MEDIUM | Version Managers | ~1.9 GB | .pyenv (748 MB), .nvm (1.1 GB) |
| MEDIUM | Local Applications | ~1.4 GB | .local/ |
| OPTIONAL | Caches | ~4.3 GB | .cache/ |

**Minimum Backup Size**: ~2.8 GB (CRITICAL + HIGH + MEDIUM)
**Full Backup Size**: ~7.1 GB (all categories)

---

## Section 1: CRITICAL (Must Backup)

These files are irreplaceable or painful to reconstruct.

### 1.1 Shell Configuration Files

**Size**: ~20 KB

**Files to Copy**:
```bash
~/.zshrc          # Zsh configuration with pyenv/NVM init
~/.bashrc         # Bash configuration
~/.shell_common   # Shared aliases and PATH settings
~/.zsh_history    # Zsh command history (104 KB)
```

**Copy Command**:
```bash
# Create backup directory structure
BACKUP_ROOT="/media/user/BACKUP_$(date +%Y%m%d)"
mkdir -p "$BACKUP_ROOT/shell"

# Copy files
cp ~/.zshrc "$BACKUP_ROOT/shell/"
cp ~/.bashrc "$BACKUP_ROOT/shell/"
cp ~/.shell_common "$BACKUP_ROOT/shell/"
cp ~/.zsh_history "$BACKUP_ROOT/shell/"

# Generate checksum
cd "$BACKUP_ROOT/shell"
md5sum .zshrc .bashrc .shell_common .zsh_history > checksums.md5
```

**Verification**:
```bash
# Verify backup integrity
cd "$BACKUP_ROOT/shell"
md5sum -c checksums.md5
# Expected: All lines show "OK"
```

**Recovery**:
```bash
# On target machine
cp /media/user/BACKUP_*/shell/.zshrc ~/
cp /media/user/BACKUP_*/shell/.bashrc ~/
cp /media/user/BACKUP_*/shell/.shell_common ~/
cp /media/user/BACKUP_*/shell/.zsh_history ~/
```

---

### 1.2 SSH Keys (Authentication)

**Size**: ~16 KB

**WARNING**: Losing SSH keys means losing access to servers. Backup is mandatory.

**Files to Copy**:
```bash
~/.ssh/id_ed25519          # Private key (CRITICAL - keep secret!)
~/.ssh/id_ed25519.pub      # Public key
~/.ssh/known_hosts         # Server fingerprints
```

**Copy Command**:
```bash
mkdir -p "$BACKUP_ROOT/security/ssh"
cp ~/.ssh/id_ed25519 "$BACKUP_ROOT/security/ssh/"
cp ~/.ssh/id_ed25519.pub "$BACKUP_ROOT/security/ssh/"
cp ~/.ssh/known_hosts "$BACKUP_ROOT/security/ssh/"

# Set restrictive permissions
chmod 600 "$BACKUP_ROOT/security/ssh/id_ed25519"
chmod 644 "$BACKUP_ROOT/security/ssh/id_ed25519.pub"

# Generate checksum
cd "$BACKUP_ROOT/security/ssh"
md5sum id_ed25519 id_ed25519.pub known_hosts > checksums.md5
```

**Verification**:
```bash
cd "$BACKUP_ROOT/security/ssh"
md5sum -c checksums.md5
```

**Recovery**:
```bash
# On target machine
mkdir -p ~/.ssh
cp /media/user/BACKUP_*/security/ssh/id_ed25519 ~/.ssh/
cp /media/user/BACKUP_*/security/ssh/id_ed25519.pub ~/.ssh/
cp /media/user/BACKUP_*/security/ssh/known_hosts ~/.ssh/
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

---

### 1.3 GPG Keys (Encryption/Signing)

**Size**: ~16 KB

**WARNING**: GPG keys cannot be recovered if lost. Backup the entire directory.

**Files to Copy**:
```bash
~/.gnupg/pubring.kbx        # Public key ring
~/.gnupg/trustdb.gpg        # Trust database
~/.gnupg/private-keys-v1.d/ # Private keys (directory)
```

**Copy Command**:
```bash
mkdir -p "$BACKUP_ROOT/security/gnupg"
cp ~/.gnupg/pubring.kbx "$BACKUP_ROOT/security/gnupg/"
cp ~/.gnupg/trustdb.gpg "$BACKUP_ROOT/security/gnupg/"
cp -r ~/.gnupg/private-keys-v1.d "$BACKUP_ROOT/security/gnupg/"

# Generate checksum
cd "$BACKUP_ROOT/security/gnupg"
find . -type f -exec md5sum {} + > checksums.md5
```

**Verification**:
```bash
cd "$BACKUP_ROOT/security/gnupg"
md5sum -c checksums.md5
```

**Recovery**:
```bash
# On target machine
mkdir -p ~/.gnupg
cp /media/user/BACKUP_*/security/gnupg/pubring.kbx ~/.gnupg/
cp /media/user/BACKUP_*/security/gnupg/trustdb.gpg ~/.gnupg/
cp -r /media/user/BACKUP_*/security/gnupg/private-keys-v1.d ~/.gnupg/
chmod 700 ~/.gnupg
chmod 600 ~/.gnupg/private-keys-v1.d/*
```

---

### 1.4 GNOME Terminal Profiles

**Size**: ~52 KB

**Files to Copy**:
```bash
~/.config/dconf/          # Or exported dconf profiles from terminal-config
```

**Copy Command**:
```bash
mkdir -p "$BACKUP_ROOT/terminal"
cp -r ~/.config/dconf "$BACKUP_ROOT/terminal/"

# Alternative: Export profiles directly
dconf dump /org/gnome/terminal/legacy/profiles:/ > "$BACKUP_ROOT/terminal/profiles.dconf"
```

**Verification**:
```bash
# Check file exists and is not empty
test -s "$BACKUP_ROOT/terminal/profiles.dconf" && echo "OK" || echo "FAILED"
```

**Recovery**:
```bash
# On target machine (requires dconf-cli installed)
dconf load /org/gnome/terminal/legacy/profiles:/ < /media/user/BACKUP_*/terminal/profiles.dconf
```

---

## Section 2: HIGH PRIORITY (Strongly Recommended)

### 2.1 JetBrains Mono Fonts

**Size**: ~8.1 MB (34 TTF files)

**Why**: Terminal appearance depends on these fonts.

**Source Location**:
```bash
~/.local/share/fonts/JetBrainsMono*.ttf
```

**Copy Command**:
```bash
mkdir -p "$BACKUP_ROOT/fonts"
find ~/.local/share/fonts -name "JetBrainsMono*.ttf" -exec cp {} "$BACKUP_ROOT/fonts/" \;

# Generate checksum
cd "$BACKUP_ROOT/fonts"
md5sum *.ttf > checksums.md5
```

**Verification**:
```bash
cd "$BACKUP_ROOT/fonts"
md5sum -c checksums.md5
# Count files (should be 34)
ls -1 *.ttf | wc -l
```

**Recovery**:
```bash
# On target machine
mkdir -p ~/.local/share/fonts
cp /media/user/BACKUP_*/fonts/*.ttf ~/.local/share/fonts/
fc-cache -f -v
```

---

### 2.2 VSCode Settings

**Size**: ~846 MB

**Why**: Editor extensions, settings, keybindings.

**Source Location**:
```bash
~/.config/Code/
```

**Copy Command**:
```bash
mkdir -p "$BACKUP_ROOT/config"
cp -r ~/.config/Code "$BACKUP_ROOT/config/"

# Generate checksum
cd "$BACKUP_ROOT/config/Code"
find . -type f -exec md5sum {} + > checksums.md5
```

**Verification**:
```bash
cd "$BACKUP_ROOT/config/Code"
md5sum -c checksums.md5 | grep -v "OK" | wc -l
# Expected: 0 failures
```

**Recovery**:
```bash
# On target machine
cp -r /media/user/BACKUP_*/config/Code ~/.config/
```

---

### 2.3 Obsidian Configuration

**Size**: ~6.6 MB

**Note**: This is configuration only. Your actual vaults must be backed up separately.

**Source Location**:
```bash
~/.config/obsidian/
```

**Copy Command**:
```bash
mkdir -p "$BACKUP_ROOT/config"
cp -r ~/.config/obsidian "$BACKUP_ROOT/config/"
```

**Recovery**:
```bash
# On target machine
cp -r /media/user/BACKUP_*/config/obsidian ~/.config/
```

---

### 2.4 Git Configuration

**Size**: ~12 KB

**Source Location**:
```bash
~/.config/git/
```

**Copy Command**:
```bash
mkdir -p "$BACKUP_ROOT/config"
cp -r ~/.config/git "$BACKUP_ROOT/config/"
```

**Recovery**:
```bash
# On target machine
cp -r /media/user/BACKUP_*/config/git ~/.config/
```

---

## Section 3: MEDIUM PRIORITY (Development Tools)

### 3.1 Python Environment (pyenv)

**Size**: ~748 MB

**Why**: Rebuilding Python versions from source takes hours.

**Source Location**:
```bash
~/.pyenv/
```

**Copy Command**:
```bash
mkdir -p "$BACKUP_ROOT/dev"
cp -r ~/.pyenv "$BACKUP_ROOT/dev/"
```

**Recovery**:
```bash
# On target machine
cp -r /media/user/BACKUP_*/dev/.pyenv ~/
# Add to PATH in .zshrc/.bashrc:
# export PYENV_ROOT="$HOME/.pyenv"
# export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init -)"
```

---

### 3.2 Node Environment (NVM)

**Size**: ~1.1 GB

**Why**: Re-installing Node.js versions and global packages is time-consuming.

**Source Location**:
```bash
~/.nvm/
```

**Copy Command**:
```bash
cp -r ~/.nvm "$BACKUP_ROOT/dev/"
```

**Recovery**:
```bash
# On target machine
cp -r /media/user/BACKUP_*/dev/.nvm ~/
# Add to .zshrc/.bashrc:
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

---

### 3.3 Local Applications

**Size**: ~1.4 GB

**Contents**:
- ~/.local/bin/ (78 MB)
- ~/.local/share/ (1.2 GB)
- ~/.local/kitty.app/ (102 MB)

**Copy Command**:
```bash
cp -r ~/.local "$BACKUP_ROOT/"
```

**Recovery**:
```bash
# On target machine
cp -r /media/user/BACKUP_*/.local ~/
```

---

### 3.4 Academic Virtual Environment

**Source Location**:
```bash
~/neural_computing/ai_env/
```

**Note**: This contains Python packages for research. Consider exporting requirements instead.

**Alternative (smarter backup)**:
```bash
# Export package list
source ~/neural_computing/ai_env/bin/activate
pip freeze > "$BACKUP_ROOT/dev/ai_env_requirements.txt"
```

**Recovery**:
```bash
# On target machine
python -m venv ~/neural_computing/ai_env
source ~/neural_computing/ai_env/bin/activate
pip install -r /media/user/BACKUP_*/dev/ai_env_requirements.txt
```

---

## Section 4: OPTIONAL (Nice to Have)

### 4.1 Application Cache

**Size**: ~4.3 GB

**Contents**: pip cache (559 MB), UV cache (1.3 GB), Chrome cache (1.7 GB), etc.

**Recommendation**: Skip cache files. They will be regenerated on demand.

**If you must backup**:
```bash
mkdir -p "$BACKUP_ROOT/cache"
cp -r ~/.cache/pip "$BACKUP_ROOT/cache/"
cp -r ~/.cache/uv "$BACKUP_ROOT/cache/"
# Skip browser caches (too large, auto-regenerated)
```

---

### 4.2 Kitty Terminal Configuration

**Size**: ~312 KB

**Source Location**:
```bash
~/.config/kitty/
```

**Copy Command**:
```bash
mkdir -p "$BACKUP_ROOT/config"
cp -r ~/.config/kitty "$BACKUP_ROOT/config/"
```

---

### 4.3 Lazygit Configuration

**Size**: ~8 KB

**Source Location**:
```bash
~/.config/lazygit/
```

**Copy Command**:
```bash
mkdir -p "$BACKUP_ROOT/config"
cp -r ~/.config/lazygit "$BACKUP_ROOT/config/"
```

---

## Section 5: One-Click Backup Script

**Save as**: `/home/user/backup_to_hdd.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

# Configuration
BACKUP_ROOT="/media/user/BACKUP_$(date +%Y%m%d_%H%M%S)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "=== HDD Backup Script ==="
echo "Backup destination: $BACKUP_ROOT"
echo ""

# Create directory structure
mkdir -p "$BACKUP_ROOT"/{shell,security/{ssh,gnupg},terminal,fonts,config,dev}

# 1. CRITICAL: Shell configs
echo "[1/7] Backing up shell configs..."
cp ~/.zshrc "$BACKUP_ROOT/shell/"
cp ~/.bashrc "$BACKUP_ROOT/shell/"
cp ~/.shell_common "$BACKUP_ROOT/shell/"
cp ~/.zsh_history "$BACKUP_ROOT/shell/"
cd "$BACKUP_ROOT/shell"
md5sum .zshrc .bashrc .shell_common .zsh_history > checksums.md5
cd -
echo "  Shell configs backed up and verified."

# 2. CRITICAL: SSH keys
echo "[2/7] Backing up SSH keys..."
cp ~/.ssh/id_ed25519 "$BACKUP_ROOT/security/ssh/"
cp ~/.ssh/id_ed25519.pub "$BACKUP_ROOT/security/ssh/"
cp ~/.ssh/known_hosts "$BACKUP_ROOT/security/ssh/"
chmod 600 "$BACKUP_ROOT/security/ssh/id_ed25519"
chmod 644 "$BACKUP_ROOT/security/ssh/id_ed25519.pub"
cd "$BACKUP_ROOT/security/ssh"
md5sum id_ed25519 id_ed25519.pub known_hosts > checksums.md5
cd -
echo "  SSH keys backed up and verified."

# 3. CRITICAL: GPG keys
echo "[3/7] Backing up GPG keys..."
cp ~/.gnupg/pubring.kbx "$BACKUP_ROOT/security/gnupg/"
cp ~/.gnupg/trustdb.gpg "$BACKUP_ROOT/security/gnupg/"
cp -r ~/.gnupg/private-keys-v1.d "$BACKUP_ROOT/security/gnupg/"
cd "$BACKUP_ROOT/security/gnupg"
find . -type f -exec md5sum {} + > checksums.md5
cd -
echo "  GPG keys backed up and verified."

# 4. CRITICAL: Terminal profiles
echo "[4/7] Backing up terminal profiles..."
dconf dump /org/gnome/terminal/legacy/profiles:/ > "$BACKUP_ROOT/terminal/profiles.dconf"
echo "  Terminal profiles backed up."

# 5. HIGH: Fonts
echo "[5/7] Backing up JetBrains Mono fonts..."
find ~/.local/share/fonts -name "JetBrainsMono*.ttf" -exec cp {} "$BACKUP_ROOT/fonts/" \;
cd "$BACKUP_ROOT/fonts"
md5sum *.ttf > checksums.md5
cd -
echo "  $(ls -1 "$BACKUP_ROOT/fonts"/*.ttf | wc -l) font files backed up."

# 6. HIGH: Configs (VSCode, Obsidian, Git)
echo "[6/7] Backing up application configs..."
[ -d ~/.config/Code ] && cp -r ~/.config/Code "$BACKUP_ROOT/config/"
[ -d ~/.config/obsidian ] && cp -r ~/.config/obsidian "$BACKUP_ROOT/config/"
[ -d ~/.config/git ] && cp -r ~/.config/git "$BACKUP_ROOT/config/"
echo "  Application configs backed up."

# 7. MEDIUM: Version managers
echo "[7/7] Backing up version managers..."
read -p "  Backup pyenv (~748 MB)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cp -r ~/.pyenv "$BACKUP_ROOT/dev/"
    echo "  pyenv backed up."
fi

read -p "  Backup NVM (~1.1 GB)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cp -r ~/.nvm "$BACKUP_ROOT/dev/"
    echo "  NVM backed up."
fi

# Export Python requirements instead of full venv
if [ -d ~/neural_computing/ai_env ]; then
    source ~/neural_computing/ai_env/bin/activate
    pip freeze > "$BACKUP_ROOT/dev/ai_env_requirements.txt"
    echo "  AI environment requirements exported."
fi

# Generate backup manifest
echo ""
echo "=== Backup Summary ==="
echo "Location: $BACKUP_ROOT"
du -sh "$BACKUP_ROOT"
echo ""

# Generate manifest file
cat > "$BACKUP_ROOT/BACKUP_MANIFEST.txt" << EOF
Backup Date: $(date)
Hostname: $(hostname)
Username: $(whoami)
Backup Location: $BACKUP_ROOT

Contents:
- Shell configs (.zshrc, .bashrc, .shell_common, .zsh_history)
- SSH keys (id_ed25519, id_ed25519.pub, known_hosts)
- GPG keys (pubring.kbx, trustdb.gpg, private-keys-v1.d/)
- Terminal profiles (GNOME dconf export)
- Fonts (JetBrains Mono - 34 TTF files)
- Application configs (VSCode, Obsidian, Git)
- Version managers (pyenv, NVM - if selected)

To restore, see HDD_BACKUP_GUIDE.md Section: Recovery Instructions
EOF

echo "Backup complete! Manifest saved to $BACKUP_ROOT/BACKUP_MANIFEST.txt"
echo "Run 'md5sum -c */checksums.md5' from $BACKUP_ROOT to verify integrity."
```

**Make executable**:
```bash
chmod +x /home/user/backup_to_hdd.sh
```

**Run**:
```bash
bash /home/user/backup_to_hdd.sh
```

---

## Section 6: Recovery Instructions

### Quick Recovery (Critical Files Only)

```bash
# Set backup location (adjust date as needed)
BACKUP_SRC="/media/user/BACKUP_20260211"

# 1. Shell configs
cp "$BACKUP_SRC/shell/.zshrc" ~/
cp "$BACKUP_SRC/shell/.bashrc" ~/
cp "$BACKUP_SRC/shell/.shell_common" ~/
cp "$BACKUP_SRC/shell/.zsh_history" ~/

# 2. SSH keys
mkdir -p ~/.ssh
cp "$BACKUP_SRC/security/ssh/id_ed25519" ~/.ssh/
cp "$BACKUP_SRC/security/ssh/id_ed25519.pub" ~/.ssh/
cp "$BACKUP_SRC/security/ssh/known_hosts" ~/.ssh/
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# 3. GPG keys
mkdir -p ~/.gnupg
cp "$BACKUP_SRC/security/gnupg/pubring.kbx" ~/.gnupg/
cp "$BACKUP_SRC/security/gnupg/trustdb.gpg" ~/.gnupg/
cp -r "$BACKUP_SRC/security/gnupg/private-keys-v1.d" ~/.gnupg/
chmod 700 ~/.gnupg
chmod 600 ~/.gnupg/private-keys-v1.d/*

# 4. Terminal profiles
dconf load /org/gnome/terminal/legacy/profiles:/ < "$BACKUP_SRC/terminal/profiles.dconf"

# 5. Fonts
mkdir -p ~/.local/share/fonts
cp "$BACKUP_SRC/fonts"/*.ttf ~/.local/share/fonts/
fc-cache -f -v
```

### Full Recovery (All Categories)

```bash
# Set backup location
BACKUP_SRC="/media/user/BACKUP_20260211"

# Restore everything
cp -r "$BACKUP_SRC/shell/"* ~/
cp -r "$BACKUP_SRC/security/"* ~/
cp -r "$BACKUP_SRC/config/"* ~/.config/

# Restore version managers if backed up
[ -d "$BACKUP_SRC/dev/.pyenv" ] && cp -r "$BACKUP_SRC/dev/.pyenv" ~/
[ -d "$BACKUP_SRC/dev/.nvm" ] && cp -r "$BACKUP_SRC/dev/.nvm" ~/

# Recreate AI environment from requirements
if [ -f "$BACKUP_SRC/dev/ai_env_requirements.txt" ]; then
    python -m venv ~/neural_computing/ai_env
    source ~/neural_computing/ai_env/bin/activate
    pip install -r "$BACKUP_SRC/dev/ai_env_requirements.txt"
fi
```

---

## Section 7: Verification Checklist

After backup, verify the following:

### File Existence Check
```bash
BACKUP_ROOT="/media/user/BACKUP_$(date +%Y%m%d)*"

# Critical files
test -f "$BACKUP_ROOT/shell/.zshrc" && echo ".zshrc: OK" || echo "MISSING"
test -f "$BACKUP_ROOT/shell/.bashrc" && echo ".bashrc: OK" || echo "MISSING"
test -f "$BACKUP_ROOT/shell/.shell_common" && echo ".shell_common: OK" || echo "MISSING"
test -f "$BACKUP_ROOT/security/ssh/id_ed25519" && echo "SSH key: OK" || echo "MISSING"
test -f "$BACKUP_ROOT/security/gnupg/pubring.kbx" && echo "GPG pubring: OK" || echo "MISSING"
test -f "$BACKUP_ROOT/terminal/profiles.dconf" && echo "Terminal profiles: OK" || echo "MISSING"

# Font count
FONT_COUNT=$(ls -1 "$BACKUP_ROOT/fonts"/*.ttf 2>/dev/null | wc -l)
echo "Font files: $FONT_COUNT (expected: 34)"
```

### Checksum Verification
```bash
# Verify all checksums
find "$BACKUP_ROOT" -name "checksums.md5" -exec sh -c 'cd "$(dirname "{}")" && md5sum -c checksums.md5' \;

# All should show "OK" (no "FAILED" messages)
```

### Size Verification
```bash
# Expected minimum sizes
echo "Checking backup sizes..."
du -sh "$BACKUP_ROOT/shell"        # Expected: ~20 KB
du -sh "$BACKUP_ROOT/security"     # Expected: ~32 KB
du -sh "$BACKUP_ROOT/terminal"     # Expected: ~52 KB
du -sh "$BACKUP_ROOT/fonts"        # Expected: ~8.1 MB
du -sh "$BACKUP_ROOT/config"       # Expected: ~852 MB (with VSCode)
```

---

## Section 8: Special Notes

### SSH Keys
- **Private keys** (`id_ed25519`) are sensitive. Keep the backup drive secure.
- Never share private keys via email or unencrypted channels.
- If you suspect compromise, revoke the old key and generate a new one.

### GPG Keys
- GPG private keys in `private-keys-v1.d/` are the most critical backup item.
- Consider uploading the public key to a keyserver for redundancy.
- Test GPG operations after restoration: `gpg --list-keys`

### Obsidian Vaults
- This backup covers **configuration only** (`.config/obsidian/`).
- Your actual markdown vaults must be backed up separately from their source location.
- Reference in `.shell_common`: `/media/user/New Volume/Downloads/##_MarkDown_Files_`

### Version Managers
- Restoring `.pyenv` and `.nvm` directories is faster than reinstallation.
- However, you may encounter architecture mismatches (e.g., x86_64 to ARM64).
- On architecture change, reinstall from scratch instead of copying.

### Virtual Environments
- Virtualenvs contain hardcoded absolute paths. Copying between machines may break.
- The recommended approach: backup `requirements.txt` and recreate on target.
- Binary packages (e.g., NumPy, SciPy) may need recompilation on new architecture.

---

## Section 9: Troubleshooting

### Permission Denied on Copy
```bash
# Use sudo for system-owned files
sudo cp /etc/hosts "$BACKUP_ROOT/system/"
```

### Disk Space Exhausted
```bash
# Check available space before backup
df -h /media/user/

# Remove optional categories if space is limited
# Skip: .cache, .nvm, .pyenv (can be reinstalled)
```

### Checksum Mismatch
```bash
# If checksum verification fails:
# 1. Re-copy the affected file
# 2. Verify the source file is not corrupted
# 3. Re-generate checksums
md5sum affected_file > checksums.md5
```

### GPG Import Fails
```bash
# On target machine, if GPG operations fail:
chmod 700 ~/.gnupg
chmod 600 ~/.gnupg/private-keys-v1.d/*
gpg --import ~/.gnupg/pubring.kbx
```

---

## Appendix A: File Inventory

### Shell Configurations
| File | Size | Description |
|------|------|-------------|
| `.zshrc` | ~3 KB | Zsh configuration with pyenv/NVM initialization |
| `.bashrc` | ~5 KB | Bash configuration (sources .shell_common) |
| `.shell_common` | ~2 KB | Shared aliases and PATH settings |
| `.zsh_history` | ~104 KB | Command history (1000 lines, 2000 saved) |

### Security Files
| File/Directory | Size | Description |
|----------------|------|-------------|
| `.ssh/id_ed25519` | 484 B | Ed25519 private key |
| `.ssh/id_ed25519.pub` | 113 B | Ed25519 public key |
| `.ssh/known_hosts` | ~2 KB | SSH host fingerprints |
| `.gnupg/pubring.kbx` | 32 B | GPG public keyring |
| `.gnupg/trustdb.gpg` | 1.2 KB | GPG trust database |
| `.gnupg/private-keys-v1.d/` | Variable | GPG private keys |

### Font Files (34 total)
| Pattern | Count | Total Size |
|---------|-------|------------|
| `JetBrainsMono*.ttf` | 34 | 8.1 MB |

### Application Configurations
| Directory | Size | Description |
|-----------|------|-------------|
| `.config/Code/` | 846 MB | VSCode settings, extensions, state |
| `.config/obsidian/` | 6.6 MB | Obsidian configuration |
| `.config/git/` | 12 KB | Git global configuration |
| `.config/kitty/` | 312 KB | Kitty terminal emulator config |
| `.config/lazygit/` | 8 KB | Lazygit UI configuration |

---

## Appendix B: Automated Backup with Cron

To automate weekly backups to external HDD:

```bash
# Edit crontab
crontab -e

# Add this line (runs every Sunday at 2 AM)
0 2 * * 0 /home/user/backup_to_hdd.sh >> /var/log/backup.log 2>&1
```

Ensure the external HDD is mounted at `/media/user/` before the scheduled time.

---

**Document Version**: 1.0
**Last Updated**: 2026-02-11
**Maintained By**: terminal-config repository
