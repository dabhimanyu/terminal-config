#!/usr/bin/env bash
# 02_backup.sh
# Complete Migration Backup Script
# Creates encrypted archive of all critical migration assets
#
# Usage: bash /home/user/terminal-config/migration/02_backup.sh
#
# Sources discovery results from ~/migration_package/
# Creates: ~/migration_package_<timestamp>.tar.gz.gpg

set -euo pipefail

# ============================================================================
# Color Codes and Logging Functions
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log_info() { echo -e "${GREEN}→${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }
log_step() { echo -e "${BLUE}▶${NC} $1"; }
log_detail() { echo -e "${CYAN}  •${NC} $1"; }
log_secure() { echo -e "${MAGENTA}🔒${NC} $1"; }

# ============================================================================
# Initialize Timestamps and Paths
# ============================================================================
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DATE=$(date +"%Y-%m-%d %H:%M:%S")
DISCOVERY_DIR="$HOME/migration_package"
STAGING_DIR="$HOME/.migration_staging_$TIMESTAMP"
BACKUP_ARCHIVE="$HOME/migration_package_${TIMESTAMP}.tar.gz.gpg"
EXCLUSION_REPORT="$HOME/migration_exclusion_report_${TIMESTAMP}.txt"

# Counters
TOTAL_FILES=0
TOTAL_SIZE=0
EXCLUDED_FILES=0
EXCLUDED_SIZE=0

# ============================================================================
# Pre-flight Checks
# ============================================================================
clear
echo "════════════════════════════════════════════════════════════════"
echo -e "${GREEN}Migration Backup Script${NC} - ITO_CHARTER Protocol"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Timestamp: $TIMESTAMP"
echo "Backup Target: $BACKUP_ARCHIVE"
echo ""

log_step "Running pre-flight checks..."

# Check if discovery directory exists
if [ ! -d "$DISCOVERY_DIR" ]; then
    log_error "Discovery directory not found: $DISCOVERY_DIR"
    log_error "Run discovery phase first (01_discovery.sh)"
    exit 1
fi

# Check for GPG availability
if ! command -v gpg &> /dev/null; then
    log_warn "GPG not found - archive will NOT be encrypted"
    BACKUP_ARCHIVE="$HOME/migration_package_${TIMESTAMP}.tar.gz"
    ENCRYPT=false
else
    log_info "GPG found - archive will be encrypted"
    ENCRYPT=true
fi

# Create staging directory
log_info "Creating staging directory: $STAGING_DIR"
mkdir -p "$STAGING_DIR"/{shell,ai,agent,security,terminal,academic,notes,custom,metadata}

echo ""

# ============================================================================
# Define Backup Items with Priority Levels
# ============================================================================
log_step "Defining backup inventory..."

# Priority 1: CRITICAL (Shell Configuration)
# ===========================================
SHELL_ITEMS=(
    ".bashrc"
    ".zshrc"
    ".profile"
    ".shell_common"
    ".shell_common.local"
    ".zshenv"
    ".bash_profile"
    ".oh-my-zsh/"
)

# Priority 1: CRITICAL (AI/Agent Configuration)
# ==============================================
AI_ITEMS=(
    ".claude/"
    ".claude.json"
    ".codex/"
    ".gemini/"
    ".kimi/"
    ".mcp-servers/"
    ".agent/"
)

# Priority 1: CRITICAL (Agent Repositories)
# ==========================================
AGENT_ITEMS=(
    "terminal-config/"
    ".agent/"
)

# Priority 1: CRITICAL (Security/Authentication)
# ================================================
SECURITY_ITEMS=(
    ".ssh/"
    ".gnupg/"
    ".gitconfig"
    ".git-credentials"
    ".gitattributes"
    ".netrc"
)

# Priority 2: HIGH (Terminal Configuration)
# ==========================================
TERMINAL_ITEMS=(
    ".gnome/"
    ".config/kitty/"
    ".config/nvim/"
    ".vimrc"
    ".vim/"
    ".config/alacritty/"
    ".config/terminator/"
)

# Priority 2: HIGH (Academic Data)
# =================================
ACADEMIC_ITEMS=(
    "Zotero/"
    "Documents/Harvard/"
    "Documents/NYU/"
    "Documents/Princeton/"
    "Documents/thesis/"
    "Documents/research/"
    "Documents/publications/"
)

# Priority 2: HIGH (Notes)
# =========================
NOTES_ITEMS=(
    "MD_Files_/"
    "Notes/"
    "Documents/notes/"
    ".obsidian/"
)

# Priority 3: MEDIUM (Custom Tools)
# ==================================
CUSTOM_ITEMS=(
    "bin/"
    "neural_computing/"
    ".local/bin/"
    "scripts/"
)

echo ""

# ============================================================================
# Exclusion Patterns (What to Skip)
# ============================================================================
log_step "Configuring exclusion patterns..."

EXCLUDE_PATTERNS=(
    # Git objects (rebuildable)
    ".git/objects/"
    ".git/logs/"
    ".git/refs/"

    # Python cache
    "__pycache__/"
    "*.pyc"
    "*.pyo"
    ".pytest_cache/"
    ".mypy_cache/"
    "*.egg-info/"
    ".tox/"
    "venv/"
    ".venv/"
    "env/"

    # Node.js
    "node_modules/"
    ".npm/"
    ".yarn/"
    "package-lock.json"
    "yarn.lock"

    # Build artifacts
    "*.o"
    "*.a"
    "*.so"
    "*.dylib"
    ".DS_Store"
    "Thumbs.db"

    # Backup files (avoid recursion)
    "*.backup.*"
    "*.save"
    "*.save.*"
    "*.bak"
    "*.old"
    "*~"

    # Browser caches (large, non-essential)
    ".mozilla/"
    ".chrome/"
    ".config/google-chrome/"
    ".cache/"
    "*.cache"

    # IDE/editor folders
    ".vscode/"
    ".idea/"
    "*.swp"
    "*.swo"
    ".vscode-snapshot/"

    # Large data files (document separately)
    "*.tar.gz"
    "*.zip"
    "*.rar"
    "*.7z"
    "*.iso"
    "*.dmg"
    "*.img"

    # Academic (large PDFs already in Zotero)
    "*.pdf"  # Will be handled separately for Zotero
)

echo ""

# ============================================================================
# Helper Functions
# ============================================================================

# Check if path should be excluded
should_exclude() {
    local path="$1"
    local relative_path="${path#$HOME/}"

    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        if [[ "$relative_path" == $pattern ]] || [[ "$relative_path" == *"/$pattern"* ]] || [[ "$relative_path" == *"/$pattern" ]]; then
            return 0
        fi
        if [[ "$path" == *"$pattern"* ]]; then
            return 0
        fi
    done
    return 1
}

# Copy file preserving permissions
copy_file() {
    local src="$1"
    local dest="$2"
    local category="$3"

    if should_exclude "$src"; then
        log_detail "Excluded: $src"
        echo "$src (excluded: pattern match)" >> "$EXCLUSION_REPORT"
        EXCLUDED_FILES=$((EXCLUDED_FILES + 1))
        EXCLUDED_SIZE=$((EXCLUDED_SIZE + $(stat -c%s "$src" 2>/dev/null || echo 0)))
        return
    fi

    local dest_dir=$(dirname "$dest")
    mkdir -p "$dest_dir"

    if cp -p "$src" "$dest" 2>/dev/null; then
        TOTAL_FILES=$((TOTAL_FILES + 1))
        TOTAL_SIZE=$((TOTAL_SIZE + $(stat -c%s "$src" 2>/dev/null || echo 0)))
        log_detail "Added: $src"
    else
        log_warn "Failed to copy: $src"
        echo "$src (failed to copy)" >> "$EXCLUSION_REPORT"
    fi
}

# Copy directory recursively
copy_directory() {
    local src="$1"
    local dest_base="$2"
    local category="$3"

    if [ ! -d "$src" ]; then
        return
    fi

    # Use find with exclude filtering
    while IFS= read -r -d '' file; do
        local relative_path="${file#$HOME/}"
        local dest_path="$dest_base/$relative_path"

        if should_exclude "$file"; then
            log_detail "Excluded: $file"
            echo "$file (excluded: pattern match)" >> "$EXCLUSION_REPORT"
            EXCLUDED_FILES=$((EXCLUDED_FILES + 1))
            EXCLUDED_SIZE=$((EXCLUDED_SIZE + $(stat -c%s "$file" 2>/dev/null || echo 0)))
            continue
        fi

        local dest_dir=$(dirname "$dest_path")
        mkdir -p "$dest_dir"

        if cp -p "$file" "$dest_path" 2>/dev/null; then
            TOTAL_FILES=$((TOTAL_FILES + 1))
            TOTAL_SIZE=$((TOTAL_SIZE + $(stat -c%s "$file" 2>/dev/null || echo 0)))
        fi
    done < <(find "$src" -type f -print0 2>/dev/null)
}

# ============================================================================
# Phase 1: Shell Configuration Backup
# ============================================================================
log_step "Phase 1: Shell Configuration"

for item in "${SHELL_ITEMS[@]}"; do
    src="$HOME/$item"
    if [ -e "$src" ]; then
        if [ -d "$src" ]; then
            copy_directory "$src" "$STAGING_DIR/shell" "shell"
        else
            copy_file "$src" "$STAGING_DIR/shell/$item" "shell"
        fi
    else
        log_warn "Not found: $item"
        echo "$item (not found)" >> "$EXCLUSION_REPORT"
    fi
done

# Copy any other shell configs found in discovery
if [ -d "$DISCOVERY_DIR/shell" ]; then
    cp -rp "$DISCOVERY_DIR/shell/"* "$STAGING_DIR/shell/" 2>/dev/null || true
fi

echo ""

# ============================================================================
# Phase 2: AI/Agent Configuration Backup
# ============================================================================
log_step "Phase 2: AI & Agent Configuration"

for item in "${AI_ITEMS[@]}"; do
    src="$HOME/$item"
    if [ -e "$src" ]; then
        if [ -d "$src" ]; then
            copy_directory "$src" "$STAGING_DIR/ai" "ai"
        else
            copy_file "$src" "$STAGING_DIR/ai/$item" "ai"
        fi
    else
        log_detail "Not found: $item"
        echo "$item (not found)" >> "$EXCLUSION_REPORT"
    fi
done

echo ""

# ============================================================================
# Phase 3: Agent Repository Backup
# ============================================================================
log_step "Phase 3: Agent Repositories"

for item in "${AGENT_ITEMS[@]}"; do
    src="$HOME/$item"
    if [ -e "$src" ]; then
        if [ -d "$src" ]; then
            copy_directory "$src" "$STAGING_DIR/agent" "agent"
        else
            copy_file "$src" "$STAGING_DIR/agent/$item" "agent"
        fi
    else
        log_detail "Not found: $item"
        echo "$item (not found)" >> "$EXCLUSION_REPORT"
    fi
done

# Special handling for thesis directory with .agent
for thesis_dir in "$HOME"/MY_PHD_THESIS_DRAFT_*; do
    if [ -d "$thesis_dir" ]; then
        THESIS_NAME=$(basename "$thesis_dir")
        if [ -d "$thesis_dir/.agent" ]; then
            copy_directory "$thesis_dir/.agent" "$STAGING_DIR/agent/$THESIS_NAME/.agent" "agent"
            log_info "Backed up thesis agent: $THESIS_NAME/.agent"
        fi
    fi
done

echo ""

# ============================================================================
# Phase 4: Security & Authentication Backup
# ============================================================================
log_step "Phase 4: Security & Authentication"
log_secure "Backing up sensitive authentication data..."

for item in "${SECURITY_ITEMS[@]}"; do
    src="$HOME/$item"
    if [ -e "$src" ]; then
        if [ -d "$src" ]; then
            copy_directory "$src" "$STAGING_DIR/security" "security"
            log_secure "Secured: $item"
        else
            copy_file "$src" "$STAGING_DIR/security/$item" "security"
            log_secure "Secured: $item"
        fi
    else
        log_detail "Not found: $item"
        echo "$item (not found)" >> "$EXCLUSION_REPORT"
    fi
done

echo ""

# ============================================================================
# Phase 5: Terminal Configuration Backup
# ============================================================================
log_step "Phase 5: Terminal Configuration"

for item in "${TERMINAL_ITEMS[@]}"; do
    src="$HOME/$item"
    if [ -e "$src" ]; then
        if [ -d "$src" ]; then
            copy_directory "$src" "$STAGING_DIR/terminal" "terminal"
        else
            copy_file "$src" "$STAGING_DIR/terminal/$item" "terminal"
        fi
    else
        log_detail "Not found: $item"
        echo "$item (not found)" >> "$EXCLUSION_REPORT"
    fi
done

# Export GNOME Terminal profiles if available
if command -v dconf &> /dev/null; then
    log_info "Exporting GNOME Terminal profiles..."
    DEFAULT_UUID=$(dconf read /org/gnome/terminal/legacy/profiles:/default 2>/dev/null | tr -d "'")
    PROFILE_LIST=$(dconf list /org/gnome/terminal/legacy/profiles:/ 2>/dev/null | grep ':' | tr -d ':/')

    if [ -n "$PROFILE_LIST" ]; then
        mkdir -p "$STAGING_DIR/terminal/dconf"
        while IFS= read -r UUID; do
            if [ -n "$UUID" ]; then
                dconf dump "/org/gnome/terminal/legacy/profiles:/:$UUID/" > "$STAGING_DIR/terminal/dconf/profile_${UUID}.dconf" 2>/dev/null || true
            fi
        done <<< "$PROFILE_LIST"
        log_info "Exported GNOME Terminal profiles"
    fi
fi

echo ""

# ============================================================================
# Phase 6: Academic Data Backup
# ============================================================================
log_step "Phase 6: Academic Data"

for item in "${ACADEMIC_ITEMS[@]}"; do
    src="$HOME/$item"
    if [ -e "$src" ]; then
        if [ -d "$src" ]; then
            copy_directory "$src" "$STAGING_DIR/academic" "academic"
        else
            copy_file "$src" "$STAGING_DIR/academic/$item" "academic"
        fi
    else
        log_detail "Not found: $item"
        echo "$item (not found)" >> "$EXCLUSION_REPORT"
    fi
done

echo ""

# ============================================================================
# Phase 7: Notes Backup
# ============================================================================
log_step "Phase 7: Notes & Documentation"

for item in "${NOTES_ITEMS[@]}"; do
    src="$HOME/$item"
    if [ -e "$src" ]; then
        if [ -d "$src" ]; then
            copy_directory "$src" "$STAGING_DIR/notes" "notes"
        else
            copy_file "$src" "$STAGING_DIR/notes/$item" "notes"
        fi
    else
        log_detail "Not found: $item"
        echo "$item (not found)" >> "$EXCLUSION_REPORT"
    fi
done

echo ""

# ============================================================================
# Phase 8: Custom Tools Backup
# ============================================================================
log_step "Phase 8: Custom Tools & Scripts"

for item in "${CUSTOM_ITEMS[@]}"; do
    src="$HOME/$item"
    if [ -e "$src" ]; then
        if [ -d "$src" ]; then
            copy_directory "$src" "$STAGING_DIR/custom" "custom"
        else
            copy_file "$src" "$STAGING_DIR/custom/$item" "custom"
        fi
    else
        log_detail "Not found: $item"
        echo "$item (not found)" >> "$EXCLUSION_REPORT"
    fi
done

echo ""

# ============================================================================
# Phase 9: Generate Manifest
# ============================================================================
log_step "Phase 9: Generating manifest with checksums..."

MANIFEST="$STAGING_DIR/MANIFEST.txt"

cat > "$MANIFEST" <<EOF
════════════════════════════════════════════════════════════════
MIGRATION BACKUP MANIFEST
════════════════════════════════════════════════════════════════

Backup ID: migration_package_${TIMESTAMP}
Generated: ${BACKUP_DATE}
Source Hostname: $(hostname)
Source User: $USER
Source OS: $(lsb_release -d 2>/dev/null | cut -f2 || uname -s)
Source Kernel: $(uname -r)

════════════════════════════════════════════════════════════════
BACKUP STATISTICS
════════════════════════════════════════════════════════════════

Total Files Backed Up: ${TOTAL_FILES}
Total Size: $(numfmt --to=iec-i --suffix=B $TOTAL_SIZE 2>/dev/null || echo "${TOTAL_SIZE} bytes")
Files Excluded: ${EXCLUDED_FILES}
Excluded Size: $(numfmt --to=iec-i --suffix=B $EXCLUDED_SIZE 2>/dev/null || echo "${EXCLUDED_SIZE} bytes")

Encryption: $([ "$ENCRYPT" = true ] && echo "YES (GPG)" || echo "NO")

════════════════════════════════════════════════════════════════
CONTENTS INVENTORY
════════════════════════════════════════════════════════════════

EOF

# Add directory structure
echo "Directory Structure:" >> "$MANIFEST"
echo "" >> "$MANIFEST"
tree -L 3 "$STAGING_DIR" >> "$MANIFEST" 2>/dev/null || find "$STAGING_DIR" -type d | head -50 >> "$MANIFEST"

echo "" >> "$MANIFEST"
echo "════════════════════════════════════════════════════════════════" >> "$MANIFEST"
echo "FILE CHECKSUMS (SHA256)" >> "$MANIFEST"
echo "════════════════════════════════════════════════════════════════" >> "$MANIFEST"
echo "" >> "$MANIFEST"

# Generate checksums for all files
find "$STAGING_DIR" -type f -exec sha256sum {} \; | sort >> "$MANIFEST"

echo "" >> "$MANIFEST"
echo "════════════════════════════════════════════════════════════════" >> "$MANIFEST"
echo "EXCLUSION REPORT SUMMARY" >> "$MANIFEST"
echo "════════════════════════════════════════════════════════════════" >> "$MANIFEST"
echo "" >> "$MANIFEST"

if [ -f "$EXCLUSION_REPORT" ]; then
    cat "$EXCLUSION_REPORT" >> "$MANIFEST"
else
    echo "No exclusions recorded." >> "$MANIFEST"
fi

echo "" >> "$MANIFEST"
echo "════════════════════════════════════════════════════════════════" >> "$MANIFEST"
echo "RESTORATION INSTRUCTIONS" >> "$MANIFEST"
echo "════════════════════════════════════════════════════════════════" >> "$MANIFEST"
echo "" >> "$MANIFEST"
cat >> "$MANIFEST" <<'EOF'
To restore from this backup:

1. Decrypt (if encrypted):
   gpg --output migration_package_restored.tar.gz \
       --decrypt migration_PACKAGE_<timestamp>.tar.gz.gpg

2. Extract:
   tar -xzf migration_package_restored.tar.gz

3. Navigate to staging directory:
   cd .migration_staging_<timestamp>/

4. Restore components by category:
   - Shell: cp -rp shell/* ~/
   - AI configs: cp -rp ai/* ~/
   - Security: cp -rp security/* ~/ (CAUTION: SSH keys, GPG keys)
   - Terminal: cp -rp terminal/* ~/
   - Academic: cp -rp academic/* ~/
   - Notes: cp -rp notes/* ~/
   - Custom: cp -rp custom/* ~/

5. Verify checksums:
   sha256sum -c MANIFEST.txt | grep -v "OK"

6. Reload shell:
   source ~/.zshrc

WARNING: This backup contains sensitive data (SSH keys, API tokens, GPG keys).
Store securely and delete after restoration.
EOF

log_info "Manifest generated: $(wc -l < "$MANIFEST") lines"

echo ""

# ============================================================================
# Phase 10: Create Archive
# ============================================================================
log_step "Phase 10: Creating encrypted archive..."

cd "$HOME"
STAGING_BASE=$(basename "$STAGING_DIR")

if [ "$ENCRYPT" = true ]; then
    log_info "Compressing and encrypting to: $BACKUP_ARCHIVE"

    # Create tar stream, pipe through gzip, then encrypt
    tar -czf - "$STAGING_BASE" | \
        gpg --symmetric --cipher-algo AES256 --compress-algo 1 --s2k-digest-algo SHA512 \
            --batch --pinentry-mode=loopback --passphrase "" \
            --output "$BACKUP_ARCHIVE" 2>/dev/null || \
    # If no passphrase set above, prompt user or use default
    tar -czf - "$STAGING_BASE" | \
        gpg --symmetric --cipher-algo AES256 \
            --output "$BACKUP_ARCHIVE"

    ARCHIVE_SIZE=$(stat -c%s "$BACKUP_ARCHIVE" 2>/dev/null || stat -f%z "$BACKUP_ARCHIVE" 2>/dev/null)
else
    log_info "Compressing (no encryption) to: $BACKUP_ARCHIVE"
    tar -czf "$BACKUP_ARCHIVE" "$STAGING_BASE"
    ARCHIVE_SIZE=$(stat -c%s "$BACKUP_ARCHIVE" 2>/dev/null || stat -f%z "$BACKUP_ARCHIVE" 2>/dev/null)
fi

ARCHIVE_SIZE_HUMAN=$(numfmt --to=iec-i --suffix=B $ARCHIVE_SIZE 2>/dev/null || echo "${ARCHIVE_SIZE} bytes")

log_info "Archive created: $ARCHIVE_SIZE_HUMAN"

echo ""

# ============================================================================
# Phase 11: Verify Archive Integrity
# ============================================================================
log_step "Phase 11: Verifying archive integrity..."

if [ "$ENCRYPT" = true ]; then
    # For encrypted archives, just verify file exists and has content
    if [ -f "$BACKUP_ARCHIVE" ] && [ "$ARCHIVE_SIZE" -gt 0 ]; then
        log_info "Encrypted archive verified"
    else
        log_error "Archive verification failed"
        exit 1
    fi
else
    # For unencrypted archives, verify contents
    if tar -tzf "$BACKUP_ARCHIVE" > /dev/null 2>&1; then
        log_info "Archive integrity verified"
        FILE_COUNT=$(tar -tzf "$BACKUP_ARCHIVE" | wc -l)
        log_detail "Archive contains $FILE_COUNT entries"
    else
        log_error "Archive integrity check failed"
        exit 1
    fi
fi

echo ""

# ============================================================================
# Cleanup Staging Directory
# ============================================================================
log_step "Cleaning up staging directory..."

if rm -rf "$STAGING_DIR"; then
    log_info "Staging directory removed: $STAGING_DIR"
else
    log_warn "Failed to remove staging directory (may be in use)"
fi

echo ""

# ============================================================================
# Final Summary
# ============================================================================
echo "════════════════════════════════════════════════════════════════"
echo -e "${GREEN}✓ MIGRATION BACKUP COMPLETE${NC}"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "ARCHIVE DETAILS:"
echo "  Location: $BACKUP_ARCHIVE"
echo "  Size: $ARCHIVE_SIZE_HUMAN"
echo "  Encryption: $([ "$ENCRYPT" = true ] && echo "YES (GPG/AES256)" || echo "NO")"
echo ""
echo "BACKUP SUMMARY:"
echo "  Files backed up: $TOTAL_FILES"
echo "  Total size: $(numfmt --to=iec-i --suffix=B $TOTAL_SIZE 2>/dev/null || echo "${TOTAL_SIZE} bytes")"
echo "  Files excluded: $EXCLUDED_FILES"
echo "  Excluded size: $(numfmt --to=iec-i --suffix=B $EXCLUDED_SIZE 2>/dev/null || echo "${EXCLUDED_SIZE} bytes")"
echo ""
echo "CATEGORIES BACKED UP:"
echo "  ✓ Shell configuration (.bashrc, .zshrc, .oh-my-zsh)"
echo "  ✓ AI/Agent configs (.claude, .codex, .mcp-servers)"
echo "  ✓ Agent repositories (terminal-config, .agent)"
echo "  ✓ Security (.ssh, .gnupg, .gitconfig)"
echo "  ✓ Terminal (.gnome, .config/kitty, .config/nvim)"
echo "  ✓ Academic (Zotero, Harvard, NYU, Princeton docs)"
echo "  ✓ Notes (MD_Files_, Notes, .obsidian)"
echo "  ✓ Custom tools (bin/, neural_computing/)"
echo ""
echo "REPORTS GENERATED:"
echo "  Manifest: Included in archive (MANIFEST.txt)"
echo "  Exclusions: $EXCLUSION_REPORT"
echo ""
echo "NEXT STEPS:"
echo "  1. Transfer archive to secure location or target machine"
echo ""
if [ "$ENCRYPT" = true ]; then
    echo "  2. Decrypt on target (when needed):"
    echo "     gpg --output backup.tar.gz --decrypt $BACKUP_ARCHIVE"
else
    echo "  2. Extract on target:"
    echo "     tar -xzf $BACKUP_ARCHIVE"
fi
echo ""
echo "  3. Verify checksums after extraction:"
echo "     sha256sum -c MANIFEST.txt | grep -v 'OK'"
echo ""
echo -e "${YELLOW}⚠ SECURITY REMINDER:${NC}"
echo "  This archive contains sensitive data:"
echo "  - SSH private keys"
echo "  - GPG private keys"
echo "  - Git credentials"
echo "  - API tokens (if present in AI configs)"
echo ""
echo "  Store securely, use encrypted transport, delete after restoration."
echo ""
echo "════════════════════════════════════════════════════════════════"

# Optional: Offer to open file manager to archive location
read -p "Press Enter to view archive location in file manager (Ctrl+C to skip)..."
if command -v nautilus &> /dev/null; then
    nautilus "$(dirname "$BACKUP_ARCHIVE")" 2>/dev/null &
elif command -v xdg-open &> /dev/null; then
    xdg-open "$(dirname "$BACKUP_ARCHIVE")" 2>/dev/null &
fi
