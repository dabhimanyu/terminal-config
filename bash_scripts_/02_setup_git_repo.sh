#!/usr/bin/env bash
# 02_setup_git_repo.sh
# Initialize Git repository for terminal configuration
# Must be run AFTER 01_extract_config.sh

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

echo "════════════════════════════════════════════════════════════════"
echo "Git Repository Setup for Terminal Configuration"
echo "════════════════════════════════════════════════════════════════"
echo ""

# ============================================================================
# Prerequisites Check
# ============================================================================
log_step "Checking prerequisites"

# Check if git is installed
if ! command -v git &> /dev/null; then
    log_warn "Git not installed. Installing..."
    sudo apt update
    sudo apt install -y git
fi

log_info "✓ Git available: $(git --version)"

echo ""

# ============================================================================
# Locate Most Recent Migration Directory
# ============================================================================
log_step "Locating migration directory"

LATEST_MIGRATION=$(ls -td ~/terminal_migration_* 2>/dev/null | head -1)

if [ -z "$LATEST_MIGRATION" ]; then
    log_error "No migration directory found. Run 01_extract_config.sh first."
fi

log_info "Found: $LATEST_MIGRATION"

echo ""

# ============================================================================
# Create Git Repository Structure
# ============================================================================
log_step "Creating Git repository structure"

REPO_DIR="$HOME/terminal-config"

if [ -d "$REPO_DIR" ]; then
    log_warn "Repository directory already exists: $REPO_DIR"
    read -p "   Delete and recreate? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$REPO_DIR"
        log_info "Existing directory removed"
    else
        log_error "Aborted by user"
    fi
fi

mkdir -p "$REPO_DIR"
log_info "Created: $REPO_DIR"

echo ""

# ============================================================================
# Copy Migration Contents to Repository
# ============================================================================
log_step "Copying migration contents to repository"

# Copy shell configs
log_info "Copying shell configuration files..."
mkdir -p "$REPO_DIR/shell_configs"
cp "$LATEST_MIGRATION/shell_configs"/.zshrc "$REPO_DIR/shell_configs/"
cp "$LATEST_MIGRATION/shell_configs"/.bashrc "$REPO_DIR/shell_configs/"
cp "$LATEST_MIGRATION/shell_configs"/.shell_common "$REPO_DIR/shell_configs/"

# Copy oh-my-zsh
log_info "Copying Oh-My-Zsh framework..."
mkdir -p "$REPO_DIR/oh-my-zsh"
cp -r "$LATEST_MIGRATION/oh_my_zsh/.oh-my-zsh" "$REPO_DIR/oh-my-zsh/"

# Copy fonts (CRITICAL: These go in Git as per requirement)
log_info "Copying JetBrains Mono fonts..."
mkdir -p "$REPO_DIR/fonts"
if [ -d "$LATEST_MIGRATION/fonts" ] && [ "$(ls -A "$LATEST_MIGRATION/fonts" 2>/dev/null)" ]; then
    cp "$LATEST_MIGRATION/fonts"/*.ttf "$REPO_DIR/fonts/" 2>/dev/null || true
    FONT_COUNT=$(ls "$REPO_DIR/fonts"/*.ttf 2>/dev/null | wc -l)
    log_info "✓ Copied $FONT_COUNT font files to repository"
else
    log_warn "No fonts found in migration package"
    touch "$REPO_DIR/fonts/.gitkeep"
fi

# Copy dconf profiles
log_info "Copying GNOME Terminal profiles..."
mkdir -p "$REPO_DIR/dconf"
cp "$LATEST_MIGRATION/dconf"/*.dconf "$REPO_DIR/dconf/" 2>/dev/null || true
PROFILE_COUNT=$(ls "$REPO_DIR/dconf"/*.dconf 2>/dev/null | wc -l)
log_info "✓ Copied $PROFILE_COUNT profile files"

# Copy metadata
log_info "Copying metadata..."
mkdir -p "$REPO_DIR/metadata"
cp "$LATEST_MIGRATION/metadata"/*.txt "$REPO_DIR/metadata/" 2>/dev/null || true

# Copy manifest
cp "$LATEST_MIGRATION/MANIFEST.md" "$REPO_DIR/" 2>/dev/null || true

echo ""

# ============================================================================
# Create Deployment Scripts Directory
# ============================================================================
log_step "Creating deployment scripts structure"

mkdir -p "$REPO_DIR/deployment"

log_info "Deployment scripts will be created in next phase"
log_info "✓ Directory structure ready"

echo ""

# ============================================================================
# Create README.md
# ============================================================================
log_step "Creating README.md"

cat > "$REPO_DIR/README.md" <<'EOF'
# Terminal Configuration for Research Environment

Comprehensive terminal environment configuration for Ubuntu-based systems with Zsh, Oh-My-Zsh, JetBrains Mono fonts, and custom GNOME Terminal profiles.

## Components

- **Shell Configurations** (`.zshrc`, `.bashrc`, `.shell_common`)
  - Single Source of Truth pattern for shared logic
  - Custom aliases and PATH management
  - Virtual environment integration

- **Oh-My-Zsh Framework**
  - Complete framework with themes
  - Plugins (auto-suggestions, syntax highlighting) cloned during deployment

- **JetBrains Mono Fonts**
  - Complete font family included in repository
  - 50+ variants (Regular, Bold, Italic, etc.)

- **GNOME Terminal Profiles**
  - All custom profiles exported
  - Colors, fonts, and palettes preserved
  - UUID-agnostic import on target machine

## Quick Start

### On Source Machine (Already Done)
```bash
# Extract configuration
bash 01_extract_config.sh

# Setup Git repository
bash 02_setup_git_repo.sh
```

### On Target Machine

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/terminal-config.git
cd terminal-config

# Run deployment
bash deployment/install.sh

# Validate installation
bash deployment/validate.sh
```

## Repository Structure

```
terminal-config/
├── README.md                 # This file
├── MANIFEST.md              # Detailed package contents
├── shell_configs/           # Shell RC files
│   ├── .zshrc
│   ├── .bashrc
│   └── .shell_common
├── oh-my-zsh/              # Oh-My-Zsh framework
│   └── .oh-my-zsh/
├── fonts/                   # JetBrains Mono TTF files
│   └── *.ttf
├── dconf/                   # GNOME Terminal profiles
│   └── profile_*.dconf
├── metadata/                # Migration metadata
│   ├── all_profiles.txt
│   ├── default_profile_details.txt
│   └── font_inventory.txt
└── deployment/              # Deployment automation
    ├── install.sh
    ├── validate.sh
    └── DEPLOY.md
```

## Path Dependencies

The following aliases in `.shell_common` contain hardcoded paths that may need updating on the target machine:

- `obs` - Obsidian vault path
- `activate_ai` - Python virtual environment path

Edit `~/.shell_common` after deployment to update these paths.

## Optional: Additional Fonts

To install Fira Code (with ligatures):
```bash
sudo apt install fonts-firacode
fc-cache -f -v
```

## Requirements

- Ubuntu 20.04+ (or compatible Debian-based distribution)
- Zsh 5.8+
- GNOME Terminal 3.36+
- Git 2.25+

## Support

For issues or questions, refer to:
- Deployment documentation: `deployment/DEPLOY.md`
- Validation script: `deployment/validate.sh`
- Migration manifest: `MANIFEST.md`

## License

Personal configuration files. Use and modify as needed.
EOF

log_info "✓ README.md created"

echo ""

# ============================================================================
# Create .gitignore
# ============================================================================
log_step "Creating .gitignore"

cat > "$REPO_DIR/.gitignore" <<'EOF'
# Zsh cache files
*.zwc
.zcompdump*

# Oh-My-Zsh cache
oh-my-zsh/.oh-my-zsh/cache/

# Oh-My-Zsh log files
oh-my-zsh/.oh-my-zsh/log/*
!oh-my-zsh/.oh-my-zsh/log/.gitkeep

# Plugin directories (cloned during deployment)
oh-my-zsh/.oh-my-zsh/custom/plugins/zsh-autosuggestions/
oh-my-zsh/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/

# User-specific overrides
.shell_common.local

# Backup files
*.bak
*.pre-migration

# macOS
.DS_Store

# Editor files
.vscode/
.idea/
*.swp
*.swo
*~

# Temporary files
*.tmp
.cache/
EOF

log_info "✓ .gitignore created"

echo ""

# ============================================================================
# Initialize Git Repository
# ============================================================================
log_step "Initializing Git repository"

cd "$REPO_DIR"

git init
log_info "✓ Git repository initialized"

# Configure Git if not already configured
if [ -z "$(git config --global user.name)" ]; then
    log_warn "Git user.name not configured"
    read -p "   Enter your name: " git_name
    git config --global user.name "$git_name"
fi

if [ -z "$(git config --global user.email)" ]; then
    log_warn "Git user.email not configured"
    read -p "   Enter your email: " git_email
    git config --global user.email "$git_email"
fi

log_info "Git configured:"
log_info "  Name: $(git config --global user.name)"
log_info "  Email: $(git config --global user.email)"

echo ""

# ============================================================================
# Create Initial Commit (WITHOUT deployment scripts yet)
# ============================================================================
log_step "Creating initial commit"

git add .
git commit -m "Initial commit: Terminal configuration state vector

Includes:
- Shell configs (.zshrc, .bashrc, .shell_common)
- Oh-My-Zsh framework (themes, no plugins)
- JetBrains Mono fonts ($FONT_COUNT .ttf files)
- GNOME Terminal profiles ($PROFILE_COUNT profiles)
- Metadata and documentation

Deployment scripts will be added in next commit."

log_info "✓ Initial commit created"

echo ""

# ============================================================================
# Repository Status Summary
# ============================================================================
log_step "Repository status"

echo ""
echo "  Repository size:"
du -sh "$REPO_DIR" | awk '{print "    " $1}'

echo ""
echo "  File count by type:"
echo "    Shell configs: $(ls "$REPO_DIR/shell_configs" 2>/dev/null | wc -l)"
echo "    Fonts: $(ls "$REPO_DIR/fonts"/*.ttf 2>/dev/null | wc -l)"
echo "    Profiles: $(ls "$REPO_DIR/dconf"/*.dconf 2>/dev/null | wc -l)"

echo ""
echo "  Git status:"
git log --oneline | head -5 | sed 's/^/    /'

echo ""

# ============================================================================
# Next Steps Instructions
# ============================================================================
echo "════════════════════════════════════════════════════════════════"
echo -e "${GREEN}✓ Git Repository Setup Complete${NC}"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Repository location: $REPO_DIR"
echo ""
echo "NEXT STEPS:"
echo ""
echo "1. Create GitHub repository:"
echo "   - Go to https://github.com/new"
echo "   - Name: terminal-config"
echo "   - Do NOT initialize with README (we have one)"
echo ""
echo "2. Add remote and push:"
echo "   cd $REPO_DIR"
echo "   git remote add origin https://github.com/YOUR_USERNAME/terminal-config.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "3. Deployment scripts will be created in Phase 3"
echo ""
