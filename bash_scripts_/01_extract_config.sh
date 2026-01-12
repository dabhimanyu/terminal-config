#!/usr/bin/env bash
# 01_extract_config.sh
# Extract complete terminal configuration state vector
# Captures: shell configs, oh-my-zsh, ALL fonts, ALL profiles

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}→${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; exit 1; }
log_step() { echo -e "${BLUE}▶${NC} $1"; }

# ============================================================================
# Initialize Migration Workspace
# ============================================================================
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MIGRATION_DIR="$HOME/terminal_migration_$TIMESTAMP"

log_step "Initializing migration workspace"
log_info "Creating directory structure: $MIGRATION_DIR"

mkdir -p "$MIGRATION_DIR"/{shell_configs,oh_my_zsh,fonts,dconf,metadata}

echo ""

# ============================================================================
# 1. Extract Shell Configuration Files
# ============================================================================
log_step "Phase 1: Extracting shell configuration files"

for file in .zshrc .bashrc .shell_common; do
    if [ -f "$HOME/$file" ]; then
        cp "$HOME/$file" "$MIGRATION_DIR/shell_configs/"
        log_info "✓ Extracted $file"
    else
        log_warn "File not found: $file (skipping)"
    fi
done

echo ""

# ============================================================================
# 2. Extract Oh-My-Zsh Framework
# ============================================================================
log_step "Phase 2: Extracting Oh-My-Zsh framework"

if [ -d ~/.oh-my-zsh ]; then
    log_info "Copying framework directory..."
    cp -r ~/.oh-my-zsh "$MIGRATION_DIR/oh_my_zsh/"
    
    # Remove plugin directories (will be re-cloned on target for version freshness)
    log_info "Removing plugin directories (will be re-cloned on target)..."
    rm -rf "$MIGRATION_DIR/oh_my_zsh/.oh-my-zsh/custom/plugins/zsh-autosuggestions" 2>/dev/null || true
    rm -rf "$MIGRATION_DIR/oh_my_zsh/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" 2>/dev/null || true
    
    log_info "✓ Framework extracted"
else
    log_error "Oh-My-Zsh directory not found at ~/.oh-my-zsh"
fi

echo ""

# ============================================================================
# 3. Extract JetBrains Mono Fonts (CORRECTED: Recursive find)
# ============================================================================
log_step "Phase 3: Extracting JetBrains Mono fonts"

log_info "Searching for JetBrains Mono .ttf files recursively..."
FONT_COUNT=$(find ~/.local/share/fonts -name "JetBrainsMono*.ttf" -type f 2>/dev/null | wc -l)

if [ $FONT_COUNT -gt 0 ]; then
    log_info "Found $FONT_COUNT font files"
    log_info "Copying fonts to migration directory..."
    
    # Use find with -exec to handle nested directory structure
    find ~/.local/share/fonts -name "JetBrainsMono*.ttf" -type f -exec cp {} "$MIGRATION_DIR/fonts/" \;
    
    # Verify extraction
    EXTRACTED_COUNT=$(ls "$MIGRATION_DIR/fonts"/*.ttf 2>/dev/null | wc -l)
    log_info "✓ Extracted $EXTRACTED_COUNT font files"
    
    # Create font inventory
    log_info "Creating font inventory..."
    ls -lh "$MIGRATION_DIR/fonts"/*.ttf > "$MIGRATION_DIR/metadata/font_inventory.txt"
else
    log_warn "No JetBrains Mono fonts found in ~/.local/share/fonts"
    log_warn "Fonts will need to be downloaded during deployment"
fi

echo ""

# ============================================================================
# 4. Extract ALL GNOME Terminal Profiles
# ============================================================================
log_step "Phase 4: Extracting ALL GNOME Terminal profiles"

# Get default profile UUID first
DEFAULT_UUID=$(dconf read /org/gnome/terminal/legacy/profiles:/default 2>/dev/null | tr -d "'")

if [ -n "$DEFAULT_UUID" ]; then
    log_info "Default profile UUID: $DEFAULT_UUID"
else
    log_warn "No default profile set"
fi

# Get list of all profile UUIDs
log_info "Enumerating all profiles..."
PROFILE_LIST=$(dconf list /org/gnome/terminal/legacy/profiles:/ 2>/dev/null | grep ':' | tr -d ':/')

if [ -n "$PROFILE_LIST" ]; then
    PROFILE_COUNT=0
    
    # Create metadata file header
    cat > "$MIGRATION_DIR/metadata/all_profiles.txt" <<EOF
GNOME Terminal Profile Inventory
Generated: $(date)
Source User: $USER
Source Hostname: $(hostname)

DEFAULT_PROFILE_UUID=$DEFAULT_UUID

Profile Details:
================
EOF
    
    # Loop through each profile and export
    while IFS= read -r UUID; do
        if [ -n "$UUID" ]; then
            PROFILE_COUNT=$((PROFILE_COUNT + 1))
            
            # Get profile name
            PROFILE_NAME=$(dconf read "/org/gnome/terminal/legacy/profiles:/:$UUID/visible-name" 2>/dev/null | tr -d "'")
            
            # Export profile
            dconf dump "/org/gnome/terminal/legacy/profiles:/:$UUID/" > "$MIGRATION_DIR/dconf/profile_${UUID}.dconf"
            
            # Record in metadata
            if [ "$UUID" = "$DEFAULT_UUID" ]; then
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
    
    log_info "✓ Total profiles exported: $PROFILE_COUNT"
else
    log_warn "No profiles found to export"
fi

echo ""

# ============================================================================
# 5. Extract Default Profile Details (for quick reference)
# ============================================================================
log_step "Phase 5: Extracting default profile details"

if [ -n "$DEFAULT_UUID" ]; then
    PROFILE_NAME=$(dconf read "/org/gnome/terminal/legacy/profiles:/:$DEFAULT_UUID/visible-name" 2>/dev/null | tr -d "'")
    FONT=$(dconf read "/org/gnome/terminal/legacy/profiles:/:$DEFAULT_UUID/font" 2>/dev/null | tr -d "'")
    USE_SYSTEM_FONT=$(dconf read "/org/gnome/terminal/legacy/profiles:/:$DEFAULT_UUID/use-system-font" 2>/dev/null)
    BG_COLOR=$(dconf read "/org/gnome/terminal/legacy/profiles:/:$DEFAULT_UUID/background-color" 2>/dev/null | tr -d "'")
    FG_COLOR=$(dconf read "/org/gnome/terminal/legacy/profiles:/:$DEFAULT_UUID/foreground-color" 2>/dev/null | tr -d "'")
    
    cat > "$MIGRATION_DIR/metadata/default_profile_details.txt" <<EOF
Default Profile Configuration
==============================

Profile Name: $PROFILE_NAME
UUID: $DEFAULT_UUID
Font: $FONT
Use System Font: $USE_SYSTEM_FONT
Background Color: $BG_COLOR
Foreground Color: $FG_COLOR

This profile will be set as default on the target machine.
EOF
    
    log_info "Default profile: \"$PROFILE_NAME\""
    log_info "Font: $FONT"
    log_info "✓ Default profile details saved"
else
    log_warn "No default profile to document"
fi

echo ""

# ============================================================================
# 6. Create Comprehensive Migration Manifest
# ============================================================================
log_step "Phase 6: Creating migration manifest"

cat > "$MIGRATION_DIR/MANIFEST.md" <<EOF
# Terminal Environment Migration Package

**Package ID:** terminal_migration_$TIMESTAMP  
**Generated:** $(date)  
**Source Hostname:** $(hostname)  
**Source User:** $USER  
**Source OS:** $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")  
**Source Kernel:** $(uname -r)

---

## Package Contents

### 1. Shell Configuration Files (\`shell_configs/\`)
- \`.zshrc\` - Zsh runtime configuration
- \`.bashrc\` - Bash runtime configuration (fallback/compatibility)
- \`.shell_common\` - Shared aliases and PATH logic (Single Source of Truth)

### 2. Oh-My-Zsh Framework (\`oh_my_zsh/\`)
- Complete framework directory
- Themes preserved
- Plugins EXCLUDED (will be re-cloned from upstream during deployment)

### 3. Font Assets (\`fonts/\`)
- JetBrains Mono font family: $FONT_COUNT .ttf files
- See \`metadata/font_inventory.txt\` for complete list

### 4. GNOME Terminal Profiles (\`dconf/\`)
- Total profiles: $PROFILE_COUNT
- Default profile UUID: $DEFAULT_UUID
- Default profile name: \"$PROFILE_NAME\"
- See \`metadata/all_profiles.txt\` for complete inventory

### 5. Metadata (\`metadata/\`)
- \`all_profiles.txt\` - Complete profile inventory with UUIDs
- \`default_profile_details.txt\` - Default profile configuration
- \`font_inventory.txt\` - Font file listing

---

## Critical Path Dependencies

The following aliases in \`.shell_common\` contain hardcoded paths:

\`\`\`bash
$(grep "^alias" ~/.shell_common 2>/dev/null || echo "# No aliases found")
\`\`\`

**⚠ ACTION REQUIRED:** Update these paths on the target machine if:
- Username differs
- Mount points differ
- Virtual environment paths differ

---

## Virtual Environment Dependencies

The following virtual environments are referenced but NOT included:

\`\`\`
$(grep -o "source.*venv.*activate\|source.*env.*activate" ~/.shell_common 2>/dev/null || echo "# No venv references detected")
\`\`\`

These must be recreated on the target machine.

---

## Deployment Instructions

1. Transfer this migration package to the target machine
2. Extract: \`tar -xzf terminal_backup_$TIMESTAMP.tar.gz\`
3. Navigate to repository: \`cd terminal-config/\`
4. Run deployment script: \`bash deployment/install.sh\`
5. Log out and log back in
6. Run validation: \`bash deployment/validate.sh\`

Detailed instructions: See \`deployment/DEPLOY.md\`

---

## Verification Checksums

\`\`\`
$(find "$MIGRATION_DIR" -type f -name "*.ttf" -o -name "*.dconf" -o -name ".zshrc" -o -name ".bashrc" | head -10 | xargs -I {} sh -c 'echo "$(md5sum {} 2>/dev/null || md5 {})"')
\`\`\`

---

**Migration Package Ready for Transport**
EOF

log_info "✓ Manifest created"

echo ""

# ============================================================================
# 7. Compress Migration Package
# ============================================================================
log_step "Phase 7: Compressing migration package"

log_info "Creating tarball: terminal_backup_$TIMESTAMP.tar.gz"
cd ~
tar -czf "terminal_backup_$TIMESTAMP.tar.gz" "terminal_migration_$TIMESTAMP"

# Get tarball size
TARBALL_SIZE=$(du -h "terminal_backup_$TIMESTAMP.tar.gz" | cut -f1)

log_info "✓ Compression complete"
log_info "Tarball size: $TARBALL_SIZE"

echo ""

# ============================================================================
# Completion Summary
# ============================================================================
echo "════════════════════════════════════════════════════════════════"
echo -e "${GREEN}✓ Migration Package Created Successfully${NC}"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "PACKAGE DETAILS:"
echo "  Archive: $HOME/terminal_backup_$TIMESTAMP.tar.gz"
echo "  Workspace: $MIGRATION_DIR"
echo "  Size: $TARBALL_SIZE"
echo ""
echo "CONTENTS SUMMARY:"
echo "  Shell configs: 3 files (.zshrc, .bashrc, .shell_common)"
echo "  Oh-My-Zsh: Framework + themes"
echo "  Fonts: $FONT_COUNT JetBrains Mono .ttf files"
echo "  Profiles: $PROFILE_COUNT GNOME Terminal profiles"
echo ""
echo "NEXT STEPS:"
echo "  1. Verify tarball integrity:"
echo "     tar -tzf ~/terminal_backup_$TIMESTAMP.tar.gz | head -20"
echo ""
echo "  2. Transfer to target machine"
echo ""
echo "  3. Set up Git repository (instructions follow)"
echo ""
