#!/usr/bin/env bash
# 01_discover.sh
# Comprehensive workstation migration discovery script
# Discovers and catalogs: shell configs, terminal settings, AI/agent configs,
# version managers, git/SSH keys, academic tools, and installed packages
#
# Usage: bash migration/01_discover.sh
# Output: ~/migration_package/ directory with complete inventory

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[+]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
log_step() { echo -e "${BLUE}[▶]${NC} $1"; }
log_detail() { echo -e "${CYAN}  →${NC} $1"; }
log_meta() { echo -e "${MAGENTA}[M]${NC} $1"; }

# ============================================================================
# Initialize Migration Package Workspace
# ============================================================================
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MIGRATION_PKG="$HOME/migration_package"
MIGRATION_METADATA="$MIGRATION_PKG/metadata"

log_step "Phase 0: Initialize Migration Package Workspace"
log_info "Creating output directory: $MIGRATION_PKG"

# Clean up any existing migration package
if [ -d "$MIGRATION_PKG" ]; then
    log_warn "Existing migration package found, backing up..."
    mv "$MIGRATION_PKG" "${MIGRATION_PKG}.backup_${TIMESTAMP}"
fi

mkdir -p "$MIGRATION_PKG"/{metadata,exports,configs,inventories}
mkdir -p "$MIGRATION_METADATA"

log_info "Migration package workspace initialized"
echo ""

# ============================================================================
# System Information Collection
# ============================================================================
log_step "Phase 1: System Information Collection"

cat > "$MIGRATION_METADATA/system_info.txt" <<EOF
WORKSTATION MIGRATION DISCOVERY REPORT
=======================================
Generated: $(date)
Source Hostname: $(hostname)
Source Username: $USER
Source OS: $(lsb_release -d 2>/dev/null | cut -f2- || echo "Unknown Linux Distribution")
Source Kernel: $(uname -r)
Source Architecture: $(uname -m)
Source Shell: $SHELL
Terminal: $(echo $TERM)

SYSTEM RESOURCES:
-----------------
CPU: $(lscpu | grep "Model name" | cut -d: -f2- | xargs 2>/dev/null || echo "Unknown")
Memory: $(free -h | grep "^Mem:" | awk '{print $2}' 2>/dev/null || echo "Unknown")
Disk: $(df -h ~ | tail -1 | awk '{print $2 " total, " $4 " available"}' 2>/dev/null || echo "Unknown")

DISCOVERY SCOPE:
---------------
This catalog represents a complete snapshot of the workstation environment
ready for migration to a new machine. Use the extraction and deployment
scripts in this repository to complete the migration.
EOF

log_info "System information captured"
echo ""

# ============================================================================
# Python Environment Discovery
# ============================================================================
log_step "Phase 2: Python Environment Discovery"

# Python executable info
PYTHON_BIN=$(which python3 python 2>/dev/null | head -1)
if [ -n "$PYTHON_BIN" ]; then
    PYTHON_VERSION=$($PYTHON_BIN --version 2>&1)
    log_info "Python: $PYTHON_VERSION at $PYTHON_BIN"
    echo "$PYTHON_VERSION" > "$MIGRATION_METADATA/python_version.txt"
else
    log_warn "Python not found in PATH"
fi

# Pip packages
if command -v pip &>/dev/null; then
    log_info "Exporting pip packages..."
    pip freeze > "$MIGRATION_PKG/exports/python_packages.txt" 2>/dev/null || true
    PIP_COUNT=$(wc -l < "$MIGRATION_PKG/exports/python_packages.txt" 2>/dev/null || echo "0")
    log_detail "Found $PIP_COUNT packages"
else
    log_warn "pip not available"
fi

# Poetry projects (if installed)
if command -v poetry &>/dev/null; then
    log_info "Discovering Poetry projects..."
    poetry env list --full-path 2>/dev/null > "$MIGRATION_PKG/inventories/poetry_envs.txt" || true
fi

# Pyenv versions
if [ -d ~/.pyenv ]; then
    log_info "Discovering pyenv installation..."
    cat > "$MIGRATION_METADATA/pyenv_info.txt" <<EOF
PYENV_ROOT=${PYENV_ROOT:-$HOME/.pyenv}
PYENV_VERSION=${PYENV_VERSION:-}
EOF

    if [ -x "${PYENV_ROOT:-$HOME/.pyenv}/bin/pyenv" ]; then
        "${PYENV_ROOT:-$HOME/.pyenv}/bin/pyenv" versions --bare > "$MIGRATION_PKG/inventories/pyenv_versions.txt" 2>/dev/null || true
        "${PYENV_ROOT:-$HOME/.pyenv}/bin/pyenv" global > "$MIGRATION_PKG/inventories/pyenv_global.txt" 2>/dev/null || true
        log_detail "Pyenv versions listed"
    fi
else
    log_warn "pyenv not installed"
fi

# Virtual environments
log_info "Scanning for Python virtual environments..."
VENV_COUNT=0
for venv_dir in ~/*/{venv,.venv,env} ~/projects/*/{venv,.venv,env} ~/{neural_computing,development,workspace}/*/{venv,.venv,env}; do
    if [ -d "$venv_dir" ] && [ -f "$venv_dir/bin/activate" ]; then
        echo "$venv_dir" >> "$MIGRATION_PKG/inventories/python_venvs.txt"
        VENV_COUNT=$((VENV_COUNT + 1))
    fi
done 2>/dev/null || true
log_detail "Found $VENV_COUNT virtual environments"

echo ""

# ============================================================================
# Node.js Environment Discovery
# ============================================================================
log_step "Phase 3: Node.js Environment Discovery"

# Node executable info
NODE_BIN=$(which node nodejs 2>/dev/null | head -1)
if [ -n "$NODE_BIN" ]; then
    NODE_VERSION=$($NODE_BIN --version 2>&1)
    NPM_VERSION=$(npm --version 2>&1)
    log_info "Node.js: $NODE_VERSION at $NODE_BIN"
    log_info "npm: $NPM_VERSION"
    echo "Node: $NODE_VERSION" > "$MIGRATION_METADATA/node_version.txt"
    echo "npm: $NPM_VERSION" >> "$MIGRATION_METADATA/node_version.txt"
else
    log_warn "Node.js not found in PATH"
fi

# NVM installation
if [ -d ~/.nvm ]; then
    log_info "Discovering NVM installation..."
    echo "NVM_DIR=$HOME/.nvm" > "$MIGRATION_METADATA/nvm_info.txt"

    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # Source nvm and get installed versions
        source "$NVM_DIR/nvm.sh" 2>/dev/null
        nvm version > "$MIGRATION_PKG/inventories/nvm_current.txt" 2>/dev/null || true
        nvm ls --no-alias | grep -E "v[0-9]" | awk '{print $2}' | xargs -n1 > "$MIGRATION_PKG/inventories/nvm_versions.txt" 2>/dev/null || true
        log_detail "NVM versions listed"
    fi
else
    log_warn "NVM not installed"
fi

# Global npm packages
if command -v npm &>/dev/null; then
    log_info "Exporting global npm packages..."
    npm list -g --depth=0 --json > "$MIGRATION_PKG/exports/npm_global.json" 2>/dev/null || \
    npm list -g --depth=0 > "$MIGRATION_PKG/exports/npm_global.txt" 2>/dev/null || true
    NPM_COUNT=$(grep -c "@" "$MIGRATION_PKG/exports/npm_global.txt" 2>/dev/null || echo "0")
    log_detail "Found $NPM_COUNT global packages"
fi

echo ""

# ============================================================================
# Shell Configuration Discovery
# ============================================================================
log_step "Phase 4: Shell Configuration Discovery"

SHELL_CONFIGS=(
    ".zshrc:.zshrc"
    ".bashrc:.bashrc"
    ".shell_common:.shell_common"
    ".profile:.profile"
    ".bash_profile:.bash_profile"
    ".zprofile:.zprofile"
    ".zshenv:.zshenv"
    ".zlogin:.zlogin"
    ".zlogout:.zlogout"
)

for config_entry in "${SHELL_CONFIGS[@]}"; do
    IFS=':' read -r src_name dest_name <<< "$config_entry"
    src_path="$HOME/$src_name"
    dest_path="$MIGRATION_PKG/configs/$dest_name"

    if [ -f "$src_path" ]; then
        cp "$src_path" "$dest_path"
        FILE_SIZE=$(stat -c%s "$src_path" 2>/dev/null || stat -f%z "$src_path" 2>/dev/null)
        log_detail "Captured $src_name (${FILE_SIZE} bytes)"
    else
        log_warn "Not found: $src_name"
    fi
done

# Oh-My-Zsh discovery
if [ -d ~/.oh-my-zsh ]; then
    log_info "Oh-My-Zsh framework detected"
    OMZ_THEME=$(grep "^ZSH_THEME=" ~/.zshrc 2>/dev/null | cut -d'"' -f2 || echo "unknown")
    OMZ_PLUGINS=$(grep "^plugins=" ~/.zshrc 2>/dev/null | cut -d')' -f1 | cut -d'(' -f2 || echo "unknown")

    cat > "$MIGRATION_METADATA/ohmyzsh_info.txt" <<EOF
Oh-My-Zsh Installation
======================
Path: ~/.oh-my-zsh
Theme: $OMZ_THEME
Plugins: $OMZ_PLUGINS
EOF

    log_detail "Theme: $OMZ_THEME"
    log_detail "Plugins: $OMZ_PLUGINS"
else
    log_warn "Oh-My-Zsh not found"
fi

echo ""

# ============================================================================
# Terminal and Editor Settings Discovery
# ============================================================================
log_step "Phase 5: Terminal and Editor Settings Discovery"

# GNOME Terminal settings
if command -v dconf &>/dev/null; then
    log_info "Exporting GNOME Terminal settings..."
    dconf dump /org/gnome/terminal/ > "$MIGRATION_PKG/exports/gnome-terminal.dconf" 2>/dev/null || true

    # Get profile list
    DEFAULT_UUID=$(dconf read /org/gnome/terminal/legacy/profiles:/default 2>/dev/null | tr -d "'")
    if [ -n "$DEFAULT_UUID" ]; then
        PROFILE_NAME=$(dconf read "/org/gnome/terminal/legacy/profiles:/:$DEFAULT_UUID/visible-name" 2>/dev/null | tr -d "'")
        log_detail "Default profile: $PROFILE_NAME"
        echo "Default UUID: $DEFAULT_UUID" > "$MIGRATION_METADATA/gnome_terminal.txt"
        echo "Default Profile: $PROFILE_NAME" >> "$MIGRATION_METADATA/gnome_terminal.txt"
    fi
else
    log_warn "dconf not available"
fi

# Kitty terminal config
if [ -f ~/.config/kitty/kitty.conf ]; then
    log_info "Kitty terminal config found"
    cp ~/.config/kitty/kitty.conf "$MIGRATION_PKG/configs/kitty.conf" 2>/dev/null || true
fi

# Vim/Neovim config
if [ -f ~/.vimrc ]; then
    log_info "Vim config found"
    cp ~/.vimrc "$MIGRATION_PKG/configs/.vimrc" 2>/dev/null || true
fi

if [ -f ~/.config/nvim/init.vim ]; then
    log_info "Neovim config found"
    cp ~/.config/nvim/init.vim "$MIGRATION_PKG/configs/nvim_init.vim" 2>/dev/null || true
fi

# VSCode settings
if [ -d ~/.config/Code ]; then
    log_info "VSCode settings detected"
    cp -r ~/.config/Code/User/*.json "$MIGRATION_PKG/configs/vscode_settings/" 2>/dev/null || true
    mkdir -p "$MIGRATION_PKG/configs/vscode_settings"
    [ -f ~/.config/Code/User/settings.json ] && cp ~/.config/Code/User/settings.json "$MIGRATION_PKG/configs/vscode_settings/settings.json" 2>/dev/null || true

    # VSCode extensions
    if command -v code &>/dev/null; then
        log_info "Exporting VSCode extensions..."
        code --list-extensions > "$MIGRATION_PKG/inventories/vscode_extensions.txt" 2>/dev/null || true
        EXT_COUNT=$(wc -l < "$MIGRATION_PKG/inventories/vscode_extensions.txt" 2>/dev/null || echo "0")
        log_detail "Found $EXT_COUNT extensions"
    fi
fi

echo ""

# ============================================================================
# AI/Agent Configuration Discovery
# ============================================================================
log_step "Phase 6: AI/Agent Configuration Discovery"

AI_DIRS=(
    ".claude:Claude Code CLI"
    ".codex:Codex CLI"
    ".gemini:Gemini CLI"
    ".kimi:Kimi CLI"
    ".agent:Agent configs"
    ".mcp-servers:MCP servers"
    ".continue:Continue.dev"
    ".cursor:Cursor AI"
)

for ai_entry in "${AI_DIRS[@]}"; do
    IFS=':' read -r dir_name description <<< "$ai_entry"
    dir_path="$HOME/$dir_name"

    if [ -d "$dir_path" ]; then
        log_info "Found: $description ($dir_name)"
        echo "$dir_path" >> "$MIGRATION_PKG/inventories/ai_config_dirs.txt"

        # Create inventory of contents
        find "$dir_path" -type f -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "*.conf" 2>/dev/null | \
            head -20 > "$MIGRATION_PKG/inventories/${dir_name}_files.txt" || true
    fi
done

echo ""

# ============================================================================
# Git and SSH Discovery
# ============================================================================
log_step "Phase 7: Git and SSH Discovery"

# Git config
if [ -f ~/.gitconfig ]; then
    log_info "Git config found"
    cp ~/.gitconfig "$MIGRATION_PKG/configs/.gitconfig" 2>/dev/null || true

    # Extract key info
    GIT_USER=$(git config --global user.name 2>/dev/null || echo "Not set")
    GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "Not set")
    log_detail "Git user: $GIT_USER <$GIT_EMAIL>"
fi

if [ -d ~/.config/git ]; then
    log_info "Git config directory found"
    cp -r ~/.config/git/* "$MIGRATION_PKG/configs/git/" 2>/dev/null || true
fi

# SSH keys (inventory only, don't copy private keys)
if [ -d ~/.ssh ]; then
    log_info "SSH directory found"
    echo "$HOME/.ssh" > "$MIGRATION_METADATA/ssh_path.txt"
    ls -la ~/.ssh/*.pub 2>/dev/null > "$MIGRATION_PKG/inventories/ssh_public_keys.txt" || true
    SSH_KEY_COUNT=$(grep -c "pub" "$MIGRATION_PKG/inventories/ssh_public_keys.txt" 2>/dev/null || echo "0")
    log_detail "Found $SSH_KEY_COUNT public SSH keys"
    log_warn "Private SSH keys must be manually transferred"
fi

# GPG keys (inventory only)
if command -v gpg &>/dev/null; then
    log_info "GPG detected"
    gpg --list-secret-keys --keyid-format LONG > "$MIGRATION_PKG/inventories/gpg_keys.txt" 2>/dev/null || true
    GPG_KEY_COUNT=$(grep -c "sec" "$MIGRATION_PKG/inventories/gpg_keys.txt" 2>/dev/null || echo "0")
    log_detail "Found $GPG_KEY_COUNT GPG keys"
    log_warn "GPG keys must be manually exported with: gpg --export-secret-keys"
fi

# Git repositories in home directory
log_info "Scanning for git repositories..."
find ~ -maxdepth 3 -type d -name ".git" 2>/dev/null | \
    sed 's|/\.git$||' | \
    grep -v "/\.cache/" | \
    grep -v "/\.local/" | \
    grep -v "/node_modules/" | \
    head -30 > "$MIGRATION_PKG/inventories/git_repos.txt" || true
REPO_COUNT=$(wc -l < "$MIGRATION_PKG/inventories/git_repos.txt" 2>/dev/null || echo "0")
log_detail "Found $REPO_COUNT git repositories"

echo ""

# ============================================================================
# Academic and Research Tools Discovery
# ============================================================================
log_step "Phase 8: Academic and Research Tools Discovery"

# Zotero
if [ -d ~/.Zotero ]; then
    log_info "Zotero detected"
    echo "$HOME/.Zotero" > "$MIGRATION_PKG/inventories/zotero_path.txt"
fi

# LaTeX configs
if [ -d ~/texmf ]; then
    log_info "LaTeX texmf directory found"
    echo "$HOME/texmf" > "$MIGRATION_PKG/inventories/latex_texmf.txt"
fi

if [ -f ~/.latexmkrc ]; then
    log_info "latexmk config found"
    cp ~/.latexmkrc "$MIGRATION_PKG/configs/.latexmkrc" 2>/dev/null || true
fi

# R and RStudio
if command -v R &>/dev/null; then
    log_info "R installation detected"
    R --version > "$MIGRATION_METADATA/r_version.txt" 2>/dev/null || true
fi

echo ""

# ============================================================================
# System Package Discovery
# ============================================================================
log_step "Phase 9: System Package Discovery"

if command -v apt &>/dev/null; then
    log_info "Exporting apt packages..."
    apt list --installed > "$MIGRATION_PKG/exports/apt_packages.txt" 2>/dev/null || true
    APT_COUNT=$(wc -l < "$MIGRATION_PKG/exports/apt_packages.txt" 2>/dev/null || echo "0")
    log_detail "Found $APT_COUNT installed packages"
fi

if command -v snap &>/dev/null; then
    log_info "Exporting snap packages..."
    snap list > "$MIGRATION_PKG/exports/snap_packages.txt" 2>/dev/null || true
fi

if command -v flatpak &>/dev/null; then
    log_info "Exporting Flatpak apps..."
    flatpak list > "$MIGRATION_PKG/exports/flatpak_apps.txt" 2>/dev/null || true
fi

echo ""

# ============================================================================
# Critical File Inventory Generation
# ============================================================================
log_step "Phase 10: Critical File Inventory Generation"

cat > "$MIGRATION_PKG/MANIFEST.txt" <<EOF
WORKSTATION MIGRATION MANIFEST
==============================
Generated: $(date)
Source: $USER@$(hostname)

MIGRATION PACKAGE CONTENTS:
---------------------------

1. System Information (metadata/)
   - system_info.txt     : Complete system snapshot
   - *_version.txt       : Version info for installed tools
   - *_info.txt          : Installation path details

2. Configuration Files (configs/)
   - Shell configs (.zshrc, .bashrc, .shell_common)
   - Terminal settings (gnome-terminal, kitty)
   - Editor configs (vim, nvim, VSCode)

3. Package Exports (exports/)
   - python_packages.txt  : pip freeze output
   - npm_global.txt       : Global npm packages
   - apt_packages.txt     : System packages

4. Inventories (inventories/)
   - git_repos.txt        : All git repositories in home directory
   - ssh_public_keys.txt  : SSH public key inventory
   - gpg_keys.txt         : GPG key inventory
   - ai_config_dirs.txt   : AI/agent configuration directories

NEXT STEPS:
-----------

1. Review the generated inventories
2. Transfer migration_package directory to target machine
3. Use extraction script to capture configs to this repository
4. Commit and push to git remote
5. On target: Clone repo and run deployment/install.sh

MANUAL TRANSFER REQUIRED:
-------------------------
- SSH private keys (~/.ssh/id_rsa, etc.)
- GPG private keys (export with gpg --export-secret-keys)
- GPG trust database (export with gpg --export-ownertrust)
- Application-specific data (browser profiles, etc.)

EOF

log_info "Manifest created"

# ============================================================================
# Checksum Generation
# ============================================================================
log_step "Phase 11: Checksum Generation"

log_info "Generating file checksums..."
cd "$MIGRATION_PKG"
find . -type f -not -path "./checksums.txt" -exec sha256sum {} \; > checksums.txt 2>/dev/null || true
CHECKSUM_COUNT=$(wc -l < checksums.txt 2>/dev/null || echo "0")
log_detail "Generated $CHECKSUM_COUNT checksums"

# ============================================================================
# Final Summary
# ============================================================================
echo ""
log_step "Discovery Complete"
echo ""
echo "════════════════════════════════════════════════════════════════"
log_info "Migration Package Created Successfully"
echo "════════════════════════════════════════════════════════════════"
echo ""
log_meta "Package Location: $MIGRATION_PKG"
echo ""
echo "SUMMARY:"
echo "  Config files captured  : $(ls -1 "$MIGRATION_PKG/configs/" 2>/dev/null | wc -l)"
echo "  Package exports created: $(ls -1 "$MIGRATION_PKG/exports/" 2>/dev/null | wc -l)"
echo "  Inventories generated  : $(ls -1 "$MIGRATION_PKG/inventories/" 2>/dev/null | wc -l)"
echo "  Metadata files         : $(ls -1 "$MIGRATION_METADATA/" 2>/dev/null | wc -l)"
echo ""
echo "TOTAL SIZE: $(du -sh "$MIGRATION_PKG" 2>/dev/null | cut -f1)"
echo ""
echo "NEXT ACTIONS:"
echo "  1. Review the discovery results:"
echo "     cat $MIGRATION_PKG/MANIFEST.txt"
echo ""
echo "  2. Review inventories for completeness:"
echo "     cat $MIGRATION_PKG/inventories/git_repos.txt"
echo "     cat $MIGRATION_PKG/exports/python_packages.txt"
echo ""
echo "  3. For git migration, run:"
echo "     bash bash_scripts_/01_extract_config.sh"
echo ""
echo "════════════════════════════════════════════════════════════════"
