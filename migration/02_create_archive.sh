#!/usr/bin/env bash
# migration/02_create_archive.sh
# Create comprehensive migration archive from existing system
# Captures: system packages, version managers, configs, keys, apps data

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MIGRATION_DIR="$HOME/terminal_migration_$TIMESTAMP"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}→${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }
log_step() { echo -e "${BLUE}▶${NC} $1"; }

echo "════════════════════════════════════════════════════════════════"
echo "Create Migration Archive"
echo "════════════════════════════════════════════════════════════════"
echo ""

# ============================================================================
# Initialize Directory Structure
# ============================================================================
log_step "Initializing migration workspace"

mkdir -p "$MIGRATION_DIR"/{shell_configs,oh_my_zsh,fonts,dconf,metadata,ssh_backup,gnupg_backup,ai_configs,vscode,zotero}

log_info "Created: $MIGRATION_DIR"
echo ""

# ============================================================================
# 1. System Package List
# ============================================================================
log_step "Capturing system package list"

dpkg --get-selections | grep -v deinstall | awk '{print $1}' > "$MIGRATION_DIR/metadata/apt_packages_list.txt"
PACKAGE_COUNT=$(wc -l < "$MIGRATION_DIR/metadata/apt_packages_list.txt")
log_info "✓ Captured $PACKAGE_COUNT packages"
echo ""

# ============================================================================
# 2. Version Manager Versions
# ============================================================================
log_step "Capturing version manager versions"

# Python versions (pyenv)
if command -v pyenv &> /dev/null; then
    pyenv versions --bare > "$MIGRATION_DIR/metadata/pyenv_versions.txt" 2>/dev/null || true
    pyenv global --bare > "$MIGRATION_DIR/metadata/pyenv_global.txt" 2>/dev/null || true
    log_info "✓ Captured pyenv versions"
fi

# Node versions (nvm)
if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    source "$HOME/.nvm/nvm.sh"
    nvm ls --no-alias | grep -v 'N/A' | awk '{print $2}' | sed 's/v//' > "$MIGRATION_DIR/metadata/nvm_versions.txt" 2>/dev/null || true
    nvm version current > "$MIGRATION_DIR/metadata/nvm_default.txt" 2>/dev/null || true
    log_info "✓ Captured nvm versions"
fi

echo ""

# ============================================================================
# 3. Shell Configuration Files
# ============================================================================
log_step "Extracting shell configuration files"

for file in .zshrc .bashrc .shell_common; do
    if [[ -f "$HOME/$file" ]]; then
        cp "$HOME/$file" "$MIGRATION_DIR/shell_configs/"
        log_info "✓ Extracted $file"
    fi
done
echo ""

# ============================================================================
# 4. Oh-My-Zsh Framework
# ============================================================================
log_step "Extracting Oh-My-Zsh framework"

if [[ -d ~/.oh-my-zsh ]]; then
    cp -r ~/.oh-my-zsh "$MIGRATION_DIR/oh_my_zsh/"

    # Remove external plugins (will be re-cloned)
    rm -rf "$MIGRATION_DIR/oh_my_zsh/.oh-my-zsh/custom/plugins/zsh-autosuggestions" 2>/dev/null || true
    rm -rf "$MIGRATION_DIR/oh_my_zsh/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" 2>/dev/null || true

    log_info "✓ Framework extracted"
else
    log_warn "Oh-My-Zsh not found"
fi
echo ""

# ============================================================================
# 5. Fonts
# ============================================================================
log_step "Extracting JetBrains Mono fonts"

FONT_COUNT=$(find ~/.local/share/fonts -name "JetBrainsMono*.ttf" -type f 2>/dev/null | wc -l)

if [[ $FONT_COUNT -gt 0 ]]; then
    find ~/.local/share/fonts -name "JetBrainsMono*.ttf" -type f -exec cp {} "$MIGRATION_DIR/fonts/" \;
    ls -lh "$MIGRATION_DIR/fonts"/*.ttf > "$MIGRATION_DIR/metadata/font_inventory.txt"
    log_info "✓ Extracted $FONT_COUNT font files"
else
    log_warn "No JetBrains Mono fonts found"
fi
echo ""

# ============================================================================
# 6. GNOME Terminal Profiles
# ============================================================================
log_step "Extracting GNOME Terminal profiles"

DEFAULT_UUID=$(dconf read /org/gnome/terminal/legacy/profiles:/default 2>/dev/null | tr -d "'")
PROFILE_LIST=$(dconf list /org/gnome/terminal/legacy/profiles:/ 2>/dev/null | grep ':' | tr -d ':/')

if [[ -n "$PROFILE_LIST" ]]; then
    PROFILE_COUNT=0

    cat > "$MIGRATION_DIR/metadata/all_profiles.txt" <<EOF
GNOME Terminal Profile Inventory
Generated: $(date)
Source User: $USER
Source Hostname: $(hostname)

DEFAULT_PROFILE_UUID=$DEFAULT_UUID

Profile Details:
================
EOF

    while IFS= read -r UUID; do
        if [[ -n "$UUID" ]]; then
            PROFILE_COUNT=$((PROFILE_COUNT + 1))
            PROFILE_NAME=$(dconf read "/org/gnome/terminal/legacy/profiles:/:$UUID/visible-name" 2>/dev/null | tr -d "'")
            dconf dump "/org/gnome/terminal/legacy/profiles:/:$UUID/" > "$MIGRATION_DIR/dconf/profile_${UUID}.dconf"

            if [[ "$UUID" == "$DEFAULT_UUID" ]]; then
                echo "[$PROFILE_COUNT] UUID: $UUID" >> "$MIGRATION_DIR/metadata/all_profiles.txt"
                echo "    Name: \"$PROFILE_NAME\"" >> "$MIGRATION_DIR/metadata/all_profiles.txt"
                echo "    Status: DEFAULT PROFILE" >> "$MIGRATION_DIR/metadata/all_profiles.txt"
                log_info "[$PROFILE_COUNT] Exported: \"$PROFILE_NAME\" (DEFAULT)"
            else
                echo "[$PROFILE_COUNT] UUID: $UUID" >> "$MIGRATION_DIR/metadata/all_profiles.txt"
                echo "    Name: \"$PROFILE_NAME\"" >> "$MIGRATION_DIR/metadata/all_profiles.txt"
                log_info "[$PROFILE_COUNT] Exported: \"$PROFILE_NAME\""
            fi
            echo "" >> "$MIGRATION_DIR/metadata/all_profiles.txt"
        fi
    done <<< "$PROFILE_LIST"

    log_info "✓ Exported $PROFILE_COUNT profiles"
else
    log_warn "No profiles found"
fi
echo ""

# ============================================================================
# 7. SSH Keys (Optional)
# ============================================================================
log_step "Checking for SSH keys"

if [[ -d ~/.ssh && -n "$(find ~/.ssh -type f -not -name '*.pub' -not -name 'known_hosts')" ]]; then
    log_warn "SSH keys detected"
    read -rp "Include SSH keys in migration? [y/N] " include_ssh

    if [[ "$include_ssh" =~ ^[Yy]$ ]]; then
        mkdir -p "$MIGRATION_DIR/ssh_backup"
        cp -r ~/.ssh/* "$MIGRATION_DIR/ssh_backup/" 2>/dev/null || true
        log_info "✓ SSH keys backed up"
    else
        log_info "Skipped SSH keys"
    fi
else
    log_info "No SSH keys found"
fi
echo ""

# ============================================================================
# 8. GPG Keys (Optional)
# ============================================================================
log_step "Checking for GPG keys"

if [[ -d ~/.gnupg && -n "$(find ~/.gnupg -type f -name '*.gpg' -o -name 'private-keys-v1.d' -type d)" ]]; then
    log_warn "GPG keys detected"
    read -rp "Include GPG keys in migration? [y/N] " include_gpg

    if [[ "$include_gpg" =~ ^[Yy]$ ]]; then
        mkdir -p "$MIGRATION_DIR/gnupg_backup"
        cp -r ~/.gnupg/* "$MIGRATION_DIR/gnupg_backup/" 2>/dev/null || true
        log_info "✓ GPG keys backed up"
    else
        log_info "Skipped GPG keys"
    fi
else
    log_info "No GPG keys found"
fi
echo ""

# ============================================================================
# 9. AI Configurations
# ============================================================================
log_step "Extracting AI configurations"

ai_configs_found=false
for config_dir in .claude .codex .cursor; do
    if [[ -d "$HOME/$config_dir" ]]; then
        ai_configs_found=true
        # Copy directory contents
        cp -r "$HOME/$config_dir" "$MIGRATION_DIR/ai_configs/" 2>/dev/null || true
        log_info "✓ Extracted $config_dir"
    fi
done

if [[ "$ai_configs_found" == false ]]; then
    log_info "No AI configurations found"
fi
echo ""

# ============================================================================
# 10. VSCode Settings and Extensions
# ============================================================================
log_step "Extracting VSCode configuration"

VSCODE_CONFIG="$HOME/.config/Code/User"

if [[ -d "$VSCODE_CONFIG" ]]; then
    mkdir -p "$MIGRATION_DIR/vscode"

    # Settings
    if [[ -f "$VSCODE_CONFIG/settings.json" ]]; then
        cp "$VSCODE_CONFIG/settings.json" "$MIGRATION_DIR/vscode/"
        log_info "✓ Extracted VSCode settings"
    fi

    # Keybindings
    if [[ -f "$VSCODE_CONFIG/keybindings.json" ]]; then
        cp "$VSCODE_CONFIG/keybindings.json" "$MIGRATION_DIR/vscode/"
        log_info "✓ Extracted VSCode keybindings"
    fi

    # Extensions list
    if command -v code &> /dev/null; then
        code --list-extensions --show-versions > "$MIGRATION_DIR/vscode/extensions.txt"
        log_info "✓ Extracted VSCode extensions list"
    fi
else
    log_info "VSCode not found"
fi
echo ""

# ============================================================================
# 11. Zotero Database (Optional)
# ============================================================================
log_step "Checking for Zotero database"

ZOTERO_LOCATIONS=("$HOME/Zotero" "$HOME/.zotero")

for zotero_dir in "${ZOTERO_LOCATIONS[@]}"; do
    if [[ -d "$zotero_dir" ]]; then
        log_warn "Zotero database found at: $zotero_dir"
        read -rp "Include Zotero database in migration? [y/N] " include_zotero

        if [[ "$include_zotero" =~ ^[Yy]$ ]]; then
            cp -r "$zotero_dir" "$MIGRATION_DIR/zotero/"
            log_info "✓ Zotero database backed up"
        fi
        break
    fi
done
echo ""

# ============================================================================
# 12. Git Repositories List
# ============================================================================
log_step "Creating git repositories inventory"

read -rp "Scan workspace directory for git repositories? [y/N] " scan_workspace

if [[ "$scan_workspace" =~ ^[Yy]$ ]]; then
    read -rp "Enter workspace path [~/workspace]: " workspace_path
    workspace_path=${workspace_path:-~/workspace}
    workspace_path="${workspace_path/#\~/$HOME}"

    if [[ -d "$workspace_path" ]]; then
        > "$MIGRATION_DIR/metadata/git_repos.txt"

        find "$workspace_path" -maxdepth 3 -type d -name ".git" | while read -r git_dir; do
            repo_dir=$(dirname "$git_dir")
            repo_name=$(basename "$repo_dir")
            repo_url=$(cd "$repo_dir" && git config --get remote.origin.url 2>/dev/null || echo "no-remote")

            if [[ "$repo_url" != "no-remote" ]]; then
                echo "$repo_url|$repo_dir" >> "$MIGRATION_DIR/metadata/git_repos.txt"
                log_info "Found: $repo_name → $repo_url"
            fi
        done

        REPO_COUNT=$(wc -l < "$MIGRATION_DIR/metadata/git_repos.txt")
        log_info "✓ Found $REPO_COUNT repositories with remotes"
    fi
else
    log_info "Skipped workspace scan"
fi
echo ""

# ============================================================================
# 13. Create Manifest
# ============================================================================
log_step "Creating migration manifest"

cat > "$MIGRATION_DIR/MANIFEST.md" <<EOF
# Terminal Migration Package

**Generated:** $(date)
**Source Hostname:** $(hostname)
**Source User:** $USER
**Source OS:** $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")

---

## Package Contents

- Shell configs: .zshrc, .bashrc, .shell_common
- Oh-My-Zsh: Framework with themes and bundled plugins
- Fonts: $FONT_COUNT JetBrains Mono variants
- Terminal profiles: $PROFILE_COUNT GNOME Terminal profiles
- System packages: $PACKAGE_COUNT apt packages
- Version managers: pyenv and nvm versions captured

---

## Deployment Instructions

1. Transfer this archive to target machine
2. Extract: tar -xzf terminal_backup_$TIMESTAMP.tar.gz
3. Run deployment: bash migration/03_deploy.sh terminal_migration_$TIMESTAMP

---

## Security Notice

This archive may contain:
- SSH private keys
- GPG private keys
- API credentials in AI configs
- Sensitive application data

**⚠ Keep this archive secure and encrypted during transfer.**

EOF

log_info "✓ Manifest created"
echo ""

# ============================================================================
# 14. Compress Archive
# ============================================================================
log_step "Compressing migration package"

cd ~
tar -czf "terminal_backup_$TIMESTAMP.tar.gz" "terminal_migration_$TIMESTAMP"
ARCHIVE_SIZE=$(du -h "terminal_backup_$TIMESTAMP.tar.gz" | cut -f1)

log_info "✓ Archive created: terminal_backup_$TIMESTAMP.tar.gz"
log_info "  Size: $ARCHIVE_SIZE"
echo ""

# ============================================================================
# Completion Summary
# ============================================================================
echo "════════════════════════════════════════════════════════════════"
echo -e "${GREEN}✓ Migration Archive Complete${NC}"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "ARCHIVE DETAILS:"
echo "  Location: $HOME/terminal_backup_$TIMESTAMP.tar.gz"
echo "  Size: $ARCHIVE_SIZE"
echo "  Workspace: $MIGRATION_DIR"
echo ""
echo "CONTENTS:"
echo "  System packages: $PACKAGE_COUNT"
echo "  Python versions: $(wc -l < "$MIGRATION_DIR/metadata/pyenv_versions.txt" 2>/dev/null || echo "0")"
echo "  Node versions: $(wc -l < "$MIGRATION_DIR/metadata/nvm_versions.txt" 2>/dev/null || echo "0")"
echo "  Shell configs: 3"
echo "  Terminal profiles: $PROFILE_COUNT"
echo "  Fonts: $FONT_COUNT"
echo "  Git repos: $(wc -l < "$MIGRATION_DIR/metadata/git_repos.txt" 2>/dev/null || echo "0")"
echo ""
echo "NEXT STEPS:"
echo "  1. Review archive contents:"
echo "     tar -tzf ~/terminal_backup_$TIMESTAMP.tar.gz | less"
echo ""
echo "  2. Transfer to target machine securely:"
echo "     scp ~/terminal_backup_$TIMESTAMP.tar.gz user@target:~/"
echo ""
echo "  3. On target machine, run:"
echo "     bash migration/03_deploy.sh ~/terminal_backup_$TIMESTAMP.tar.gz"
echo ""
echo "⚠ SECURITY REMINDER:"
echo "  This archive may contain sensitive data (SSH keys, GPG keys, API creds)."
echo "  Encrypt before transfer: gpg -c terminal_backup_$TIMESTAMP.tar.gz"
echo ""
