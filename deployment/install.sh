#!/usr/bin/env bash
# deployment/install.sh
# Terminal environment deployment script for target machine
# Installs: configs, Oh-My-Zsh, fonts, profiles, plugins

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

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
echo "Terminal Environment Deployment"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Target User: $USER"
echo "Target Hostname: $(hostname)"
echo "Target OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")"
echo ""

# ============================================================================
# Phase 1: Prerequisites Installation
# ============================================================================
log_step "Phase 1: Installing prerequisites"

MISSING_PACKAGES=()

command -v zsh &> /dev/null || MISSING_PACKAGES+=("zsh")
command -v git &> /dev/null || MISSING_PACKAGES+=("git")
command -v curl &> /dev/null || MISSING_PACKAGES+=("curl")
command -v wget &> /dev/null || MISSING_PACKAGES+=("wget")
command -v unzip &> /dev/null || MISSING_PACKAGES+=("unzip")
command -v dconf &> /dev/null || MISSING_PACKAGES+=("dconf-cli")

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    log_info "Installing missing packages: ${MISSING_PACKAGES[*]}"
    sudo apt update
    sudo apt install -y "${MISSING_PACKAGES[@]}" fontconfig
    log_info "✓ Packages installed"
else
    log_info "✓ All prerequisites satisfied"
fi

echo ""

# ============================================================================
# Phase 2: Deploy Shell Configuration Files
# ============================================================================
log_step "Phase 2: Deploying shell configuration files"

for file in .zshrc .bashrc .shell_common; do
    if [ -f "$HOME/$file" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        log_warn "Existing $file detected"
        mv "$HOME/$file" "$HOME/${file}.pre-migration-${TIMESTAMP}"
        log_info "Backed up to: ${file}.pre-migration-${TIMESTAMP}"
    fi
    
    if [ -f "$REPO_ROOT/shell_configs/$file" ]; then
        cp "$REPO_ROOT/shell_configs/$file" ~/
        log_info "✓ Deployed $file"
    else
        log_error "Source file not found: $REPO_ROOT/shell_configs/$file"
    fi
done

echo ""

# ============================================================================
# Phase 3: Deploy Oh-My-Zsh Framework
# ============================================================================
log_step "Phase 3: Deploying Oh-My-Zsh framework"

if [ -d ~/.oh-my-zsh ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    log_warn "Existing Oh-My-Zsh detected"
    mv ~/.oh-my-zsh ~/.oh-my-zsh.pre-migration-${TIMESTAMP}
    log_info "Backed up to: .oh-my-zsh.pre-migration-${TIMESTAMP}"
fi

if [ -d "$REPO_ROOT/oh-my-zsh/.oh-my-zsh" ]; then
    cp -r "$REPO_ROOT/oh-my-zsh/.oh-my-zsh" ~/
    log_info "✓ Framework deployed"
else
    log_error "Framework not found in repository"
fi

echo ""

# ============================================================================
# Phase 4: Clone Essential Plugins from Upstream
# ============================================================================
log_step "Phase 4: Installing plugins from upstream"

PLUGIN_DIR="$HOME/.oh-my-zsh/custom/plugins"
mkdir -p "$PLUGIN_DIR"

# zsh-autosuggestions
if [ ! -d "$PLUGIN_DIR/zsh-autosuggestions" ]; then
    log_info "Cloning zsh-autosuggestions..."
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git \
        "$PLUGIN_DIR/zsh-autosuggestions" 2>/dev/null
    log_info "✓ zsh-autosuggestions installed"
else
    log_info "✓ zsh-autosuggestions already present"
fi

# zsh-syntax-highlighting
if [ ! -d "$PLUGIN_DIR/zsh-syntax-highlighting" ]; then
    log_info "Cloning zsh-syntax-highlighting..."
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "$PLUGIN_DIR/zsh-syntax-highlighting" 2>/dev/null
    log_info "✓ zsh-syntax-highlighting installed"
else
    log_info "✓ zsh-syntax-highlighting already present"
fi

echo ""

# ============================================================================
# Phase 5: Install JetBrains Mono Fonts
# ============================================================================
log_step "Phase 5: Installing JetBrains Mono fonts"

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

# Check if fonts exist in repository
if [ -d "$REPO_ROOT/fonts" ] && [ "$(ls -A "$REPO_ROOT/fonts"/*.ttf 2>/dev/null)" ]; then
    log_info "Fonts found in repository, copying..."
    cp "$REPO_ROOT/fonts"/*.ttf "$FONT_DIR/"
    REPO_FONT_COUNT=$(ls "$REPO_ROOT/fonts"/*.ttf 2>/dev/null | wc -l)
    log_info "Copied $REPO_FONT_COUNT font files from repository"
else
    log_warn "Fonts not in repository, downloading from GitHub..."
    cd /tmp
    
    log_info "Downloading JetBrains Mono v2.304..."
    wget -q --show-progress \
        https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip \
        -O JetBrainsMono.zip
    
    log_info "Extracting fonts..."
    unzip -q JetBrainsMono.zip -d jetbrains_temp
    cp jetbrains_temp/fonts/ttf/*.ttf "$FONT_DIR/"
    
    log_info "Cleaning up..."
    rm -rf jetbrains_temp JetBrainsMono.zip
    
    log_info "✓ Fonts downloaded and installed"
fi

log_info "Rebuilding font cache..."
fc-cache -f -v > /dev/null 2>&1

# Verify installation
INSTALLED_FONT_COUNT=$(fc-list | grep -i "JetBrains Mono" | wc -l)
if [ $INSTALLED_FONT_COUNT -gt 0 ]; then
    log_info "✓ Font verification: $INSTALLED_FONT_COUNT variants detected"
else
    log_error "Font installation failed - no fonts detected"
fi

echo ""

# ============================================================================
# Phase 6: Import ALL GNOME Terminal Profiles
# ============================================================================
log_step "Phase 6: Importing GNOME Terminal profiles"

# Backup existing profiles
DCONF_BACKUP="$HOME/gnome_terminal_backup_$(date +%Y%m%d_%H%M%S).dconf"
dconf dump /org/gnome/terminal/ > "$DCONF_BACKUP" 2>/dev/null || true
log_info "Existing profiles backed up to: $DCONF_BACKUP"

# Get default profile UUID from metadata
DEFAULT_PROFILE_UUID=""
if [ -f "$REPO_ROOT/metadata/all_profiles.txt" ]; then
    DEFAULT_PROFILE_UUID=$(grep "DEFAULT_PROFILE_UUID=" "$REPO_ROOT/metadata/all_profiles.txt" | cut -d'=' -f2)
    log_info "Original default profile UUID: $DEFAULT_PROFILE_UUID"
fi

# Import all profiles with new UUIDs
PROFILE_FILES=("$REPO_ROOT/dconf"/profile_*.dconf)
PROFILE_COUNT=0
NEW_DEFAULT_UUID=""
CURRENT_PROFILE_LIST=""

for profile_file in "${PROFILE_FILES[@]}"; do
    if [ -f "$profile_file" ]; then
        PROFILE_COUNT=$((PROFILE_COUNT + 1))
        
        # Extract original UUID from filename
        ORIG_UUID=$(basename "$profile_file" | sed 's/profile_//' | sed 's/.dconf//')
        
        # Generate new UUID for username-agnostic import
        NEW_UUID=$(uuidgen)
        PROFILE_PATH="/org/gnome/terminal/legacy/profiles:/:$NEW_UUID/"
        
        # Import profile
        dconf load "$PROFILE_PATH" < "$profile_file" 2>/dev/null
        
        # Get profile name for logging
        PROFILE_NAME=$(dconf read "$PROFILE_PATH/visible-name" 2>/dev/null | tr -d "'")
        
        # Track if this was the default profile
        if [ "$ORIG_UUID" = "$DEFAULT_PROFILE_UUID" ]; then
            NEW_DEFAULT_UUID="$NEW_UUID"
            log_info "[$PROFILE_COUNT] Imported: \"$PROFILE_NAME\" (will be set as DEFAULT)"
        else
            log_info "[$PROFILE_COUNT] Imported: \"$PROFILE_NAME\""
        fi
        
        # Build profile list
        if [ -z "$CURRENT_PROFILE_LIST" ]; then
            CURRENT_PROFILE_LIST="'$NEW_UUID'"
        else
            CURRENT_PROFILE_LIST="$CURRENT_PROFILE_LIST, '$NEW_UUID'"
        fi
    fi
done

# Update profile list in dconf
if [ $PROFILE_COUNT -gt 0 ]; then
    dconf write /org/gnome/terminal/legacy/profiles:/list "[$CURRENT_PROFILE_LIST]"
    log_info "✓ Profile list updated with $PROFILE_COUNT profiles"
    
    # Set default profile
    if [ -n "$NEW_DEFAULT_UUID" ]; then
        dconf write /org/gnome/terminal/legacy/profiles:/default "'$NEW_DEFAULT_UUID'"
        DEFAULT_NAME=$(dconf read "/org/gnome/terminal/legacy/profiles:/:$NEW_DEFAULT_UUID/visible-name" 2>/dev/null | tr -d "'")
        log_info "✓ Default profile set to: \"$DEFAULT_NAME\""
    else
        log_warn "Original default profile not found, using first imported profile"
        FIRST_UUID=$(echo "$CURRENT_PROFILE_LIST" | cut -d"'" -f2)
        dconf write /org/gnome/terminal/legacy/profiles:/default "'$FIRST_UUID'"
    fi
else
    log_warn "No profiles found to import"
fi

echo ""

# ============================================================================
# Phase 7: Set Zsh as Default Shell
# ============================================================================
log_step "Phase 7: Setting Zsh as default shell"

CURRENT_SHELL=$(basename "$SHELL")

if [ "$CURRENT_SHELL" != "zsh" ]; then
    log_info "Current shell: $CURRENT_SHELL"
    log_info "Changing default shell to Zsh..."
    chsh -s "$(which zsh)"
    log_warn "✓ Default shell changed to Zsh"
    log_warn "⚠ You MUST log out and log back in for this to take effect"
else
    log_info "✓ Zsh is already the default shell"
fi

echo ""

# ============================================================================
# Phase 8: Path Dependency Warnings
# ============================================================================
log_step "Phase 8: Checking path-dependent aliases"

if [ -f ~/.shell_common ]; then
    log_info "Path-dependent aliases detected in .shell_common:"
    echo ""
    grep "^alias" ~/.shell_common | while IFS= read -r line; do
        echo "   $line"
    done
    echo ""
    log_warn "⚠ VERIFY these paths match your system"
    log_warn "⚠ Edit ~/.shell_common if paths differ"
else
    log_info "No .shell_common file found"
fi

echo ""

# ============================================================================
# Completion Summary
# ============================================================================
echo "════════════════════════════════════════════════════════════════"
echo -e "${GREEN}✓ Deployment Complete${NC}"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "DEPLOYMENT SUMMARY:"
echo "  Shell configs: ✓ Deployed"
echo "  Oh-My-Zsh: ✓ Deployed"
echo "  Plugins: ✓ Installed (from upstream)"
echo "  Fonts: ✓ Installed ($INSTALLED_FONT_COUNT variants)"
echo "  Profiles: ✓ Imported ($PROFILE_COUNT profiles)"
echo "  Default shell: ✓ Changed to Zsh"
echo ""
echo "CRITICAL POST-DEPLOYMENT ACTIONS:"
echo ""
echo "1. LOG OUT AND LOG BACK IN (or reboot)"
echo "   This activates Zsh as your default shell"
echo ""
echo "2. Open a new terminal window"
echo "   Verify prompt appearance and colors"
echo ""
echo "3. Run validation script:"
echo "   bash $SCRIPT_DIR/validate.sh"
echo ""
echo "4. Update path-dependent aliases:"
echo "   nano ~/.shell_common"
echo "   (Update 'obs' alias and 'activate_ai' alias paths)"
echo ""
echo "5. Test functionality:"
echo "   - Type a command → Should see syntax highlighting"
echo "   - Start typing → Should see gray autosuggestions"
echo "   - Check font → Terminal → Preferences → Text tab"
echo ""
