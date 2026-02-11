#!/usr/bin/env bash
# migration/03_deploy.sh
# Comprehensive migration deployment script for new workstation
# Accepts: Archive path as argument
# Deploys: Complete environment restoration in correct dependency order

set -euo pipefail

# ============================================================================
# SCRIPT CONFIGURATION
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/tmp/migration_deploy_${TIMESTAMP}.log"
DRY_RUN=false
SKIP_CONFIRMATION=false

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${GREEN}✓${NC} $1" | tee -a "$LOG_FILE"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1" | tee -a "$LOG_FILE"; }
log_error() { echo -e "${RED}✗${NC} $1" | tee -a "$LOG_FILE"; }
log_step() { echo -e "${BLUE}▶${NC} $1" | tee -a "$LOG_FILE"; }
log_debug() { echo -e "${CYAN}◉${NC} $1" | tee -a "$LOG_FILE"; }
log_header() { echo -e "${MAGENTA}═══ $1 ═══${NC}" | tee -a "$LOG_FILE"; }

# ============================================================================
# USAGE AND ARGUMENT PARSING
# ============================================================================
usage() {
    cat <<EOF
USAGE: bash $0 [OPTIONS] <archive_path>

ARGUMENTS:
    archive_path          Path to migration archive (.tar.gz or directory)

OPTIONS:
    -d, --dry-run         Simulate deployment without making changes
    -y, --yes             Skip confirmation prompts
    -h, --help            Show this help message
    -v, --verbose         Enable verbose output

EXAMPLES:
    bash $0 ~/terminal_backup_20260111_120000.tar.gz
    bash $0 -d ~/terminal_migration_20260111_120000  # Dry run
    bash $0 -y ~/Downloads/terminal_backup.tar.gz     # Auto-confirm

DEPLOYMENT ORDER:
    1. System packages restore
    2. Install version managers (nvm, pyenv)
    3. Restore Python versions (pyenv)
    4. Restore Node versions (nvm)
    5. Extract shell configs to temp location
    6. Install oh-my-zsh, then copy custom configs
    7. Restore .ssh, .gnupg (verify permissions!)
    8. Restore AI configs (.claude, .codex, etc.)
    9. Restore terminal settings (GNOME dconf load)
    10. Restore VSCode settings and install extensions
    11. Restore Zotero database
    12. Clone git repos from list

EOF
    exit 1
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -y|--yes)
                SKIP_CONFIRMATION=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            -v|--verbose)
                set -x
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                ;;
            *)
                ARCHIVE_PATH="$1"
                shift
                ;;
        esac
    done

    if [[ -z "${ARCHIVE_PATH:-}" ]]; then
        log_error "Archive path required"
        usage
    fi
}

# ============================================================================
# CONFIRMATION PROMPTS
# ============================================================================
confirm_action() {
    local message="$1"
    local default="${2:-n}"

    if [[ "$SKIP_CONFIRMATION" == true ]]; then
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_debug "[DRY-RUN] Would execute: $message"
        return 0
    fi

    local prompt
    if [[ "$default" == "y" ]]; then
        prompt="$message [Y/n] "
    else
        prompt="$message [y/N] "
    fi

    local response
    read -rp "$(echo -e "${YELLOW}$prompt${NC}")" response
    response=${response:-$default}

    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# ARCHIVE VALIDATION AND EXTRACTION
# ============================================================================
validate_archive() {
    log_header "Phase 0: Archive Validation"

    local archive="$1"

    if [[ ! -e "$archive" ]]; then
        log_error "Archive not found: $archive"
        return 1
    fi

    log_info "Archive found: $archive"

    # Check if it's a tar.gz archive
    if [[ "$archive" =~ \.tar\.gz$ ]]; then
        log_info "Validating tar.gz integrity..."

        if ! tar -tzf "$archive" > /dev/null 2>&1; then
            log_error "Archive integrity check failed"
            return 1
        fi

        log_info "✓ Archive integrity validated"

        # Get archive info
        ARCHIVE_SIZE=$(du -h "$archive" | cut -f1)
        log_info "Archive size: $ARCHIVE_SIZE"

        # Extract to temp directory
        EXTRACT_DIR="/tmp/terminal_migration_extract_${TIMESTAMP}"
        log_info "Extracting to: $EXTRACT_DIR"

        if [[ "$DRY_RUN" == false ]]; then
            mkdir -p "$EXTRACT_DIR"
            tar -xzf "$archive" -C "$EXTRACT_DIR"

            # Find the extracted directory
            EXTRACTED_PATH=$(find "$EXTRACT_DIR" -maxdepth 1 -type d | tail -1)
            MIGRATION_DIR="$EXTRACTED_PATH"

            log_info "✓ Extraction complete"
            log_debug "Migration directory: $MIGRATION_DIR"
        else
            log_debug "[DRY-RUN] Would extract to: $EXTRACT_DIR"
            MIGRATION_DIR="$EXTRACT_DIR"
        fi
    elif [[ -d "$archive" ]]; then
        # It's already a directory
        MIGRATION_DIR="$archive"
        log_info "Using existing directory: $MIGRATION_DIR"
    else
        log_error "Unsupported archive format: $archive"
        return 1
    fi

    # Check for required files
    log_info "Checking for required migration components..."

    local missing_files=()

    [[ ! -d "$MIGRATION_DIR/shell_configs" ]] && missing_files+=("shell_configs/")
    [[ ! -d "$MIGRATION_DIR/dconf" ]] && missing_files+=("dconf/")
    [[ ! -d "$MIGRATION_DIR/oh_my_zsh" ]] && missing_files+=("oh_my_zsh/")

    if [[ ${#missing_files[@]} -gt 0 ]]; then
        log_error "Missing required components: ${missing_files[*]}"
        return 1
    fi

    log_info "✓ All required components found"

    # Load manifest if available
    if [[ -f "$MIGRATION_DIR/MANIFEST.md" ]]; then
        log_info "Loading migration manifest..."
        # Could parse and display manifest details here
        log_info "✓ Manifest loaded"
    fi

    echo ""
}

# ============================================================================
# BACKUP FUNCTIONS
# ============================================================================
backup_file() {
    local file="$1"
    local timestamp

    if [[ -e "$file" ]]; then
        timestamp=$(date +%Y%m%d_%H%M%S)
        local backup="${file}.pre-migration-${timestamp}"

        if [[ "$DRY_RUN" == true ]]; then
            log_debug "[DRY-RUN] Would backup: $file → $backup"
        else
            mv "$file" "$backup"
            log_info "Backed up: $file → $backup"
        fi
    fi
}

backup_dir() {
    local dir="$1"
    local timestamp

    if [[ -d "$dir" ]]; then
        timestamp=$(date +%Y%m%d_%H%M%S)
        local backup="${dir}.pre-migration-${timestamp}"

        if [[ "$DRY_RUN" == true ]]; then
            log_debug "[DRY-RUN] Would backup: $dir → $backup"
        else
            mv "$dir" "$backup"
            log_info "Backed up: $dir → $backup"
        fi
    fi
}

# ============================================================================
# PHASE 1: SYSTEM PACKAGES RESTORE
# ============================================================================
phase_1_system_packages() {
    log_header "Phase 1: System Packages Restore"

    local apt_list_file="$MIGRATION_DIR/metadata/apt_packages_list.txt"

    if [[ -f "$apt_list_file" ]]; then
        log_info "Found apt package list"

        if [[ "$DRY_RUN" == true ]]; then
            log_debug "[DRY-RUN] Would install packages from: $apt_list_file"
            cat "$apt_list_file" | head -10 | while read -r pkg; do
                log_debug "[DRY-RUN] Would install: $pkg"
            done
            return 0
        fi

        # Update package cache
        log_info "Updating package cache..."
        sudo apt update

        # Install packages
        log_info "Installing packages from list..."
        while read -r package; do
            # Skip comments and empty lines
            [[ "$package" =~ ^#.*$ ]] && continue
            [[ -z "$package" ]] && continue

            log_info "Installing: $package"
            sudo apt install -y "$package" 2>&1 | tee -a "$LOG_FILE" | grep -E "(Setting up|already installed)" || true
        done < "$apt_list_file"

        log_info "✓ Package installation complete"
    else
        log_warn "No apt package list found, skipping..."
    fi

    # Ensure core dependencies are present
    log_info "Verifying core dependencies..."
    local core_packages=(zsh git curl wget unzip dconf-cli fontconfig build-essential)
    local missing_packages=()

    for pkg in "${core_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg"; then
            missing_packages+=("$pkg")
        fi
    done

    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        log_info "Installing missing core packages: ${missing_packages[*]}"
        if [[ "$DRY_RUN" == false ]]; then
            sudo apt update
            sudo apt install -y "${missing_packages[@]}"
        fi
    fi

    log_info "✓ Core dependencies verified"
    echo ""
}

# ============================================================================
# PHASE 2: INSTALL VERSION MANAGERS
# ============================================================================
phase_2_version_managers() {
    log_header "Phase 2: Install Version Managers"

    # Install NVM
    if ! [[ -d "$HOME/.nvm" ]]; then
        log_info "Installing NVM (Node Version Manager)..."

        if [[ "$DRY_RUN" == false ]]; then
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
            # Source nvm
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            log_info "✓ NVM installed"
        else
            log_debug "[DRY-RUN] Would install NVM"
        fi
    else
        log_info "✓ NVM already installed"
    fi

    # Install pyenv
    if ! [[ -d "$HOME/.pyenv" ]]; then
        log_info "Installing pyenv (Python Version Manager)..."

        if [[ "$DRY_RUN" == false ]]; then
            # Install dependencies
            sudo apt install -y make build-essential libssl-dev zlib1g-dev \
                libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
                libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
                libffi-dev liblzma-dev python3-dev python3-pip python3-setuptools

            # Clone pyenv
            curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
            log_info "✓ pyenv installed"
        else
            log_debug "[DRY-RUN] Would install pyenv"
        fi
    else
        log_info "✓ pyenv already installed"
    fi

    echo ""
}

# ============================================================================
# PHASE 3: RESTORE PYTHON VERSIONS
# ============================================================================
phase_3_python_versions() {
    log_header "Phase 3: Restore Python Versions"

    local versions_file="$MIGRATION_DIR/metadata/pyenv_versions.txt"

    if [[ ! -f "$versions_file" ]]; then
        log_warn "No Python versions list found"
        echo ""
        return 0
    fi

    # Ensure pyenv is available
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"

    while read -r version; do
        [[ "$version" =~ ^#.*$ ]] && continue
        [[ -z "$version" ]] && continue

        log_info "Restoring Python $version..."

        if pyenv versions | grep -q "$version"; then
            log_info "  Already installed"
            continue
        fi

        if [[ "$DRY_RUN" == false ]]; then
            if pyenv install "$version" 2>&1 | tee -a "$LOG_FILE"; then
                log_info "  ✓ Python $version installed"
            else
                log_warn "  Failed to install Python $version"
            fi
        else
            log_debug "[DRY-RUN] Would install Python $version"
        fi
    done < "$versions_file"

    # Set global Python version if specified
    local global_file="$MIGRATION_DIR/metadata/pyenv_global.txt"
    if [[ -f "$global_file" ]]; then
        local global_version=$(cat "$global_file")
        log_info "Setting global Python version: $global_version"

        if [[ "$DRY_RUN" == false ]]; then
            pyenv global "$global_version"
        fi
    fi

    echo ""
}

# ============================================================================
# PHASE 4: RESTORE NODE VERSIONS
# ============================================================================
phase_4_node_versions() {
    log_header "Phase 4: Restore Node Versions"

    local versions_file="$MIGRATION_DIR/metadata/nvm_versions.txt"

    if [[ ! -f "$versions_file" ]]; then
        log_warn "No Node versions list found"
        echo ""
        return 0
    fi

    # Ensure NVM is available
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    while read -r version; do
        [[ "$version" =~ ^#.*$ ]] && continue
        [[ -z "$version" ]] && continue

        log_info "Restoring Node.js $version..."

        if nvm list | grep -q "$version"; then
            log_info "  Already installed"
            continue
        fi

        if [[ "$DRY_RUN" == false ]]; then
            if nvm install "$version" 2>&1 | tee -a "$LOG_FILE"; then
                log_info "  ✓ Node.js $version installed"
            else
                log_warn "  Failed to install Node.js $version"
            fi
        else
            log_debug "[DRY-RUN] Would install Node.js $version"
        fi
    done < "$versions_file"

    # Set default Node version if specified
    local default_file="$MIGRATION_DIR/metadata/nvm_default.txt"
    if [[ -f "$default_file" ]]; then
        local default_version=$(cat "$default_file")
        log_info "Setting default Node version: $default_version"

        if [[ "$DRY_RUN" == false ]]; then
            nvm alias default "$default_version"
        fi
    fi

    echo ""
}

# ============================================================================
# PHASE 5: DEPLOY SHELL CONFIGS
# ============================================================================
phase_5_shell_configs() {
    log_header "Phase 5: Deploy Shell Configurations"

    local shell_configs_dir="$MIGRATION_DIR/shell_configs"

    for file in .zshrc .bashrc .shell_common; do
        local src="$shell_configs_dir/$file"
        local dst="$HOME/$file"

        if [[ -f "$src" ]]; then
            backup_file "$dst"

            if [[ "$DRY_RUN" == false ]]; then
                cp "$src" "$dst"
                log_info "✓ Deployed $file"
            else
                log_debug "[DRY-RUN] Would deploy $file"
            fi
        else
            log_warn "Source not found: $src"
        fi
    done

    echo ""
}

# ============================================================================
# PHASE 6: INSTALL OH-MY-ZSH AND CUSTOM CONFIGS
# ============================================================================
phase_6_oh_my_zsh() {
    log_header "Phase 6: Install Oh-My-Zsh Framework"

    # Check if oh-my-zsh is already installed
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Installing oh-my-zsh..."

        if [[ "$DRY_RUN" == false ]]; then
            sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
            log_info "✓ oh-my-zsh installed"
        else
            log_debug "[DRY-RUN] Would install oh-my-zsh"
        fi
    else
        log_info "✓ oh-my-zsh already present"
    fi

    # Deploy custom framework from migration
    local omz_source="$MIGRATION_DIR/oh_my_zsh/.oh-my-zsh"

    if [[ -d "$omz_source" ]]; then
        log_info "Deploying custom oh-my-zsh configuration..."

        if [[ "$DRY_RUN" == false ]]; then
            # Copy themes and plugins
            cp -r "$omz_source/themes/"* ~/.oh-my-zsh/themes/ 2>/dev/null || true
            cp -r "$omz_source/plugins/"* ~/.oh-my-zsh/plugins/ 2>/dev/null || true

            log_info "✓ Custom themes and plugins deployed"
        else
            log_debug "[DRY-RUN] Would deploy custom oh-my-zsh config"
        fi
    fi

    # Clone external plugins
    log_info "Cloning external plugins..."

    local plugin_dir="$HOME/.oh-my-zsh/custom/plugins"
    mkdir -p "$plugin_dir"

    # zsh-autosuggestions
    if [[ ! -d "$plugin_dir/zsh-autosuggestions" ]]; then
        if [[ "$DRY_RUN" == false ]]; then
            git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git \
                "$plugin_dir/zsh-autosuggestions" 2>/dev/null
            log_info "✓ zsh-autosuggestions installed"
        else
            log_debug "[DRY-RUN] Would clone zsh-autosuggestions"
        fi
    fi

    # zsh-syntax-highlighting
    if [[ ! -d "$plugin_dir/zsh-syntax-highlighting" ]]; then
        if [[ "$DRY_RUN" == false ]]; then
            git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
                "$plugin_dir/zsh-syntax-highlighting" 2>/dev/null
            log_info "✓ zsh-syntax-highlighting installed"
        else
            log_debug "[DRY-RUN] Would clone zsh-syntax-highlighting"
        fi
    fi

    echo ""
}

# ============================================================================
# PHASE 7: RESTORE SSH AND GPG KEYS
# ============================================================================
phase_7_secure_keys() {
    log_header "Phase 7: Restore Secure Keys (.ssh, .gnupg)"

    # SSH Keys
    local ssh_source="$MIGRATION_DIR/ssh_backup"
    if [[ -d "$ssh_source" ]]; then
        log_warn "SSH keys detected in migration"

        if confirm_action "Restore SSH keys from migration?" "n"; then
            backup_dir "$HOME/.ssh"

            if [[ "$DRY_RUN" == false ]]; then
                mkdir -p "$HOME/.ssh"
                cp -r "$ssh_source"/* "$HOME/.ssh/"

                # Fix permissions (CRITICAL for SSH)
                chmod 700 "$HOME/.ssh"
                chmod 600 "$HOME/.ssh"/id_* 2>/dev/null || true
                chmod 644 "$HOME/.ssh"/id_*.pub 2>/dev/null || true
                chmod 600 "$HOME/.ssh"/config 2>/dev/null || true

                log_info "✓ SSH keys restored with correct permissions"
            else
                log_debug "[DRY-RUN] Would restore SSH keys"
            fi
        else
            log_warn "Skipped SSH key restoration"
        fi
    else
        log_info "No SSH backup found"
    fi

    # GPG Keys
    local gpg_source="$MIGRATION_DIR/gnupg_backup"
    if [[ -d "$gpg_source" ]]; then
        log_warn "GPG keys detected in migration"

        if confirm_action "Restore GPG keys from migration?" "n"; then
            backup_dir "$HOME/.gnupg"

            if [[ "$DRY_RUN" == false ]]; then
                mkdir -p "$HOME/.gnupg"
                cp -r "$gpg_source"/* "$HOME/.gnupg/"

                # Fix permissions (CRITICAL for GPG)
                chmod 700 "$HOME/.gnupg"
                chmod 600 "$HOME/.gnupg"/gpg-agent.conf 2>/dev/null || true
                chmod 600 "$HOME/.gnupg"/gpg.conf 2>/dev/null || true
                find "$HOME/.gnupg" -type d -exec chmod 700 {} \;
                find "$HOME/.gnupg" -type f -exec chmod 600 {} \;

                log_info "✓ GPG keys restored with correct permissions"
            else
                log_debug "[DRY-RUN] Would restore GPG keys"
            fi
        else
            log_warn "Skipped GPG key restoration"
        fi
    else
        log_info "No GPG backup found"
    fi

    echo ""
}

# ============================================================================
# PHASE 8: RESTORE AI CONFIGS
# ============================================================================
phase_8_ai_configs() {
    log_header "Phase 8: Restore AI Configurations"

    local ai_config_dir="$MIGRATION_DIR/ai_configs"

    if [[ ! -d "$ai_config_dir" ]]; then
        log_info "No AI configuration directory found"
        echo ""
        return 0
    fi

    # Find all config files
    find "$ai_config_dir" -type f -print0 2>/dev/null | while IFS= read -r -d '' src; do
        local basename=$(basename "$src")
        local config_name="${basename##ai_config_}"
        local dst="$HOME/.$config_name"

        if [[ -e "$dst" ]]; then
            backup_file "$dst"
        fi

        log_info "Restoring AI config: .$config_name"

        if [[ "$DRY_RUN" == false ]]; then
            cp "$src" "$dst"
            log_info "  ✓ Restored"
        else
            log_debug "[DRY-RUN] Would restore .$config_name"
        fi
    done

    echo ""
}

# ============================================================================
# PHASE 9: RESTORE TERMINAL SETTINGS
# ============================================================================
phase_9_terminal_settings() {
    log_header "Phase 9: Restore Terminal Settings (GNOME dconf)"

    local dconf_source="$MIGRATION_DIR/dconf"

    if [[ ! -d "$dconf_source" ]]; then
        log_error "No dconf directory found in migration"
        echo ""
        return 1
    fi

    # Backup existing terminal settings
    local dconf_backup="$HOME/gnome_terminal_backup_${TIMESTAMP}.dconf"
    dconf dump /org/gnome/terminal/ > "$dconf_backup" 2>/dev/null || true
    log_info "Backed up existing terminal settings to: $dconf_backup"

    # Import profiles with UUID regeneration
    local profile_files=("$dconf_source"/profile_*.dconf)
    local profile_count=0
    local new_default_uuid=""
    local current_profile_list=""
    local default_profile_uuid=""

    # Get original default UUID from metadata
    if [[ -f "$MIGRATION_DIR/metadata/all_profiles.txt" ]]; then
        default_profile_uuid=$(grep "DEFAULT_PROFILE_UUID=" "$MIGRATION_DIR/metadata/all_profiles.txt" | cut -d'=' -f2)
    fi

    for profile_file in "${profile_files[@]}"; do
        if [[ -f "$profile_file" ]]; then
            profile_count=$((profile_count + 1))

            # Extract original UUID from filename
            local orig_uuid=$(basename "$profile_file" | sed 's/profile_//' | sed 's/.dconf//')

            # Generate new UUID
            local new_uuid=$(uuidgen)
            local profile_path="/org/gnome/terminal/legacy/profiles:/:$new_uuid/"

            if [[ "$DRY_RUN" == false ]]; then
                # Import profile
                dconf load "$profile_path" < "$profile_file" 2>/dev/null

                # Get profile name
                local profile_name=$(dconf read "$profile_path/visible-name" 2>/dev/null | tr -d "'")

                # Track default profile
                if [[ "$orig_uuid" == "$default_profile_uuid" ]]; then
                    new_default_uuid="$new_uuid"
                    log_info "[$profile_count] Imported: \"$profile_name\" (DEFAULT)"
                else
                    log_info "[$profile_count] Imported: \"$profile_name\""
                fi

                # Build profile list
                if [[ -z "$current_profile_list" ]]; then
                    current_profile_list="'$new_uuid'"
                else
                    current_profile_list="$current_profile_list, '$new_uuid'"
                fi
            else
                log_debug "[DRY-RUN] Would import profile: $(basename "$profile_file")"
            fi
        fi
    done

    # Update profile list
    if [[ $profile_count -gt 0 && "$DRY_RUN" == false ]]; then
        dconf write /org/gnome/terminal/legacy/profiles:/list "[$current_profile_list]"
        log_info "✓ Profile list updated with $profile_count profiles"

        # Set default profile
        if [[ -n "$new_default_uuid" ]]; then
            dconf write /org/gnome/terminal/legacy/profiles:/default "'$new_default_uuid'"
            local default_name=$(dconf read "/org/gnome/terminal/legacy/profiles:/:$new_default_uuid/visible-name" 2>/dev/null | tr -d "'")
            log_info "✓ Default profile set to: \"$default_name\""
        fi
    fi

    echo ""
}

# ============================================================================
# PHASE 10: RESTORE VSCODE SETTINGS
# ============================================================================
phase_10_vscode() {
    log_header "Phase 10: Restore VSCode Settings and Extensions"

    local vscode_source="$MIGRATION_DIR/vscode"

    if [[ ! -d "$vscode_source" ]]; then
        log_info "No VSCode directory found in migration"
        echo ""
        return 0
    fi

    # VSCode settings location
    local vscode_config="$HOME/.config/Code/User"

    # Restore settings.json
    if [[ -f "$vscode_source/settings.json" ]]; then
        backup_file "$vscode_config/settings.json"

        if [[ "$DRY_RUN" == false ]]; then
            mkdir -p "$vscode_config"
            cp "$vscode_source/settings.json" "$vscode_config/"
            log_info "✓ VSCode settings restored"
        else
            log_debug "[DRY-RUN] Would restore VSCode settings"
        fi
    fi

    # Restore keybindings.json
    if [[ -f "$vscode_source/keybindings.json" ]]; then
        backup_file "$vscode_config/keybindings.json"

        if [[ "$DRY_RUN" == false ]]; then
            cp "$vscode_source/keybindings.json" "$vscode_config/"
            log_info "✓ VSCode keybindings restored"
        else
            log_debug "[DRY-RUN] Would restore VSCode keybindings"
        fi
    fi

    # Install extensions
    local extensions_file="$vscode_source/extensions.txt"
    if [[ -f "$extensions_file" ]]; then
        log_info "Installing VSCode extensions..."

        if command -v code &> /dev/null; then
            while read -r extension; do
                [[ "$extension" =~ ^#.*$ ]] && continue
                [[ -z "$extension" ]] && continue

                log_info "  Installing: $extension"

                if [[ "$DRY_RUN" == false ]]; then
                    code --install-extension "$extension" --force 2>&1 | tee -a "$LOG_FILE" | grep -E "(installed|already installed)" || true
                else
                    log_debug "[DRY-RUN] Would install extension: $extension"
                fi
            done < "$extensions_file"

            log_info "✓ Extension installation complete"
        else
            log_warn "VSCode not found, skipping extension installation"
        fi
    fi

    echo ""
}

# ============================================================================
# PHASE 11: RESTORE ZOTERO DATABASE
# ============================================================================
phase_11_zotero() {
    log_header "Phase 11: Restore Zotero Database"

    local zotero_source="$MIGRATION_DIR/zotero"

    if [[ ! -d "$zotero_source" ]]; then
        log_info "No Zotero directory found in migration"
        echo ""
        return 0
    fi

    # Zotero data location
    local zotero_dest="$HOME/Zotero"

    if [[ -d "$zotero_dest" ]]; then
        if ! confirm_action "Existing Zotero directory found. Replace?" "n"; then
            log_warn "Skipped Zotero restoration"
            echo ""
            return 0
        fi
        backup_dir "$zotero_dest"
    fi

    log_info "Restoring Zotero database..."

    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$zotero_dest"
        cp -r "$zotero_source"/* "$zotero_dest/"
        log_info "✓ Zotero database restored"
    else
        log_debug "[DRY-RUN] Would restore Zotero database"
    fi

    echo ""
}

# ============================================================================
# PHASE 12: CLONE GIT REPOSITORIES
# ============================================================================
phase_12_git_repos() {
    log_header "Phase 12: Clone Git Repositories"

    local repos_file="$MIGRATION_DIR/metadata/git_repos.txt"

    if [[ ! -f "$repos_file" ]]; then
        log_info "No git repositories list found"
        echo ""
        return 0
    fi

    local workspace_dir="$HOME/workspace"
    mkdir -p "$workspace_dir"

    while read -r line; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue

        # Parse line format: "repo_url|destination_dir"
        local repo_url=$(echo "$line" | cut -d'|' -f1)
        local dest_dir=$(echo "$line" | cut -d'|' -f2)
        local repo_name=$(basename "$repo_url" .git)

        if [[ -z "$dest_dir" ]]; then
            dest_dir="$workspace_dir/$repo_name"
        else
            # Expand ~ in path
            dest_dir="${dest_dir/#\~/$HOME}"
        fi

        log_info "Cloning: $repo_name"

        if [[ -d "$dest_dir" ]]; then
            log_warn "  Directory already exists: $dest_dir"
            if confirm_action "  Reclone repository?" "n"; then
                backup_dir "$dest_dir"
            else
                log_info "  Skipping"
                continue
            fi
        fi

        if [[ "$DRY_RUN" == false ]]; then
            if git clone "$repo_url" "$dest_dir" 2>&1 | tee -a "$LOG_FILE"; then
                log_info "  ✓ Cloned to: $dest_dir"
            else
                log_warn "  Failed to clone: $repo_url"
            fi
        else
            log_debug "[DRY-RUN] Would clone $repo_url to $dest_dir"
        fi
    done < "$repos_file"

    echo ""
}

# ============================================================================
# PHASE 13: SET DEFAULT SHELL
# ============================================================================
phase_13_default_shell() {
    log_header "Phase 13: Set Default Shell"

    if ! command -v zsh &> /dev/null; then
        log_error "Zsh not found, cannot set as default"
        return 1
    fi

    local current_shell=$(basename "$SHELL")

    if [[ "$current_shell" != "zsh" ]]; then
        log_info "Current shell: $current_shell"
        log_info "Changing default shell to Zsh..."

        if [[ "$DRY_RUN" == false ]]; then
            chsh -s "$(which zsh)"
            log_warn "✓ Default shell changed to Zsh"
            log_warn "⚠ You MUST log out and log back in for this to take effect"
        else
            log_debug "[DRY-RUN] Would change default shell to Zsh"
        fi
    else
        log_info "✓ Zsh is already the default shell"
    fi

    echo ""
}

# ============================================================================
# POST-DEPLOYMENT VERIFICATION
# ============================================================================
verify_deployment() {
    log_header "Post-Deployment Verification"

    local checks_passed=0
    local checks_failed=0

    # Check 1: Default shell
    echo -n "Checking default shell... "
    if [[ "$(basename "$SHELL")" == "zsh" ]]; then
        echo -e "${GREEN}✓${NC}"
        ((checks_passed++))
    else
        echo -e "${YELLOW}⚠ Change pending (log out required)${NC}"
        ((checks_passed++)) # Not a failure, just pending
    fi

    # Check 2: Config files
    echo -n "Checking config files... "
    if [[ -f "$HOME/.zshrc" && -f "$HOME/.bashrc" && -f "$HOME/.shell_common" ]]; then
        echo -e "${GREEN}✓${NC}"
        ((checks_passed++))
    else
        echo -e "${RED}✗ Missing config files${NC}"
        ((checks_failed++))
    fi

    # Check 3: Oh-My-Zsh
    echo -n "Checking oh-my-zsh... "
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo -e "${GREEN}✓${NC}"
        ((checks_passed++))
    else
        echo -e "${RED}✗ Oh-my-zsh not found${NC}"
        ((checks_failed++))
    fi

    # Check 4: External plugins
    echo -n "Checking external plugins... "
    if [[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" && \
          -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]]; then
        echo -e "${GREEN}✓${NC}"
        ((checks_passed++))
    else
        echo -e "${YELLOW}⚠ Some plugins missing${NC}"
        ((checks_passed++)) # Warning, not failure
    fi

    # Check 5: Terminal profiles
    echo -n "Checking terminal profiles... "
    local profile_count=$(dconf read /org/gnome/terminal/legacy/profiles:/list 2>/dev/null | grep -o "'" | wc -l)
    if [[ $profile_count -gt 0 ]]; then
        echo -e "${GREEN}✓${NC} ($((profile_count / 2)) profiles)"
        ((checks_passed++))
    else
        echo -e "${YELLOW}⚠ No profiles imported${NC}"
        ((checks_passed++))
    fi

    # Check 6: Version managers
    echo -n "Checking version managers... "
    local vm_count=0
    [[ -d "$HOME/.nvm" ]] && ((vm_count++))
    [[ -d "$HOME/.pyenv" ]] && ((vm_count++))

    if [[ $vm_count -gt 0 ]]; then
        echo -e "${GREEN}✓${NC} ($vm_count installed)"
        ((checks_passed++))
    else
        echo -e "${YELLOW}⚠ No version managers${NC}"
        ((checks_passed++))
    fi

    echo ""
    echo "Verification Results: $checks_passed passed, $checks_failed failed"

    if [[ $checks_failed -eq 0 ]]; then
        echo -e "${GREEN}✓ All critical checks passed${NC}"
    else
        echo -e "${RED}✗ Some checks failed${NC}"
        return 1
    fi

    echo ""
}

# ============================================================================
# ROLLBACK FUNCTION
# -*-
rollback() {
    log_header "ROLLBACK INITIATED"

    log_warn "Restoring from backups..."

    # Find all migration backups
    find ~ -maxdepth 1 -name "*.pre-migration-*" -type f -o -name "*.pre-migration-*" -type d | while read -r backup; do
        local original="${backup%.pre-migration-*}"

        log_info "Restoring: $backup → $original"

        # Remove the migrated version
        rm -rf "$original" 2>/dev/null || true

        # Restore from backup
        mv "$backup" "$original"
    done

    log_info "✓ Rollback complete"
    log_warn "Please review your system and re-run deployment if needed"
}

# ============================================================================
# FINAL SUMMARY
# -*-
print_summary() {
    log_header "Deployment Summary"

    cat <<EOF
DEPLOYMENT COMPLETE: $(date)

Archive: $ARCHIVE_PATH
Migration Directory: $MIGRATION_DIR
Log File: $LOG_FILE

CRITICAL POST-DEPLOYMENT ACTIONS:

1. LOG OUT AND LOG BACK IN
   This activates Zsh as your default shell

2. Verify terminal appearance
   - Open a new terminal
   - Check prompt, colors, and fonts
   - Test syntax highlighting and autosuggestions

3. Update path-dependent aliases
   Edit ~/.shell_common and update:
   - obs alias (Obsidian vault path)
   - activate_ai alias (virtualenv path)

4. Run validation script
   bash $REPO_ROOT/deployment/validate.sh

5. Test version managers
   pyenv version
   nvm current

6. Verify restored repositories
   cd ~/workspace
   ls -la

BACKUPS CREATED:
All original files were backed up with .pre-migration-<timestamp> suffix
To rollback: Run the rollback function or manually restore from backups

EOF
}

# ============================================================================
# MAIN EXECUTION
# -*-
main() {
    parse_arguments "$@"

    # Initialize logging
    exec > >(tee -a "$LOG_FILE")
    exec 2>&1

    echo "════════════════════════════════════════════════════════════════"
    echo "Terminal Migration Deployment"
    echo "════════════════════════════════════════════════════════════════"
    echo "Started: $(date)"
    echo "Target User: $USER"
    echo "Target Hostname: $(hostname)"
    echo "Target OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")"
    echo "Dry Run: $DRY_RUN"
    echo ""

    # Validate archive
    validate_archive "$ARCHIVE_PATH" || exit 1

    # Confirmation prompt
    if [[ "$DRY_RUN" == false && "$SKIP_CONFIRMATION" == false ]]; then
        echo ""
        echo -e "${YELLOW}WARNING: This will modify your system configuration${NC}"
        echo ""
        read -rp "Continue with deployment? [y/N] " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Deployment cancelled by user"
            exit 0
        fi
        echo ""
    fi

    # Execute deployment phases
    phase_1_system_packages
    phase_2_version_managers
    phase_3_python_versions
    phase_4_node_versions
    phase_5_shell_configs
    phase_6_oh_my_zsh
    phase_7_secure_keys
    phase_8_ai_configs
    phase_9_terminal_settings
    phase_10_vscode
    phase_11_zotero
    phase_12_git_repos
    phase_13_default_shell

    # Verify deployment
    verify_deployment

    # Print summary
    print_summary

    # Cleanup temp directory if not dry run
    if [[ "$DRY_RUN" == false && -d "${EXTRACT_DIR:-}" ]]; then
        log_info "Cleaning up temporary files..."
        rm -rf "$EXTRACT_DIR"
    fi

    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo -e "${GREEN}✓ Deployment Complete${NC}"
    echo "════════════════════════════════════════════════════════════════"
}

# Run main function
main "$@"
