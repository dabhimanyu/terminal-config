#!/usr/bin/env bash
# 03_add_deployment_scripts.sh
# Add deployment scripts and documentation to Git repository
# Run AFTER 02_setup_git_repo.sh

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
echo "Adding Deployment Scripts to Repository"
echo "════════════════════════════════════════════════════════════════"
echo ""

# ============================================================================
# Verify Repository Exists
# ============================================================================
REPO_DIR="$HOME/terminal-config"

if [ ! -d "$REPO_DIR" ]; then
    log_error "Repository not found at $REPO_DIR"
    echo "Run 02_setup_git_repo.sh first"
fi

if [ ! -d "$REPO_DIR/.git" ]; then
    log_error "Not a git repository: $REPO_DIR"
fi

log_info "Repository found: $REPO_DIR"

echo ""

# ============================================================================
# Get Script Locations
# ============================================================================
log_step "Locating deployment scripts"

# Find where this script is running from
SCRIPT_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log_info "Script source directory: $SCRIPT_SOURCE_DIR"

# Check if deployment scripts exist in current directory or /home/claude
DEPLOY_SCRIPT=""
VALIDATE_SCRIPT=""
DEPLOY_DOC=""

for dir in "$SCRIPT_SOURCE_DIR" "$HOME" "/home/claude"; do
    if [ -f "$dir/deployment_install.sh" ]; then
        DEPLOY_SCRIPT="$dir/deployment_install.sh"
    fi
    if [ -f "$dir/deployment_validate.sh" ]; then
        VALIDATE_SCRIPT="$dir/deployment_validate.sh"
    fi
    if [ -f "$dir/DEPLOY.md" ]; then
        DEPLOY_DOC="$dir/DEPLOY.md"
    fi
done

# Verify all files found
if [ -z "$DEPLOY_SCRIPT" ]; then
    log_error "deployment_install.sh not found"
fi
if [ -z "$VALIDATE_SCRIPT" ]; then
    log_error "deployment_validate.sh not found"
fi
if [ -z "$DEPLOY_DOC" ]; then
    log_error "DEPLOY.md not found"
fi

log_info "✓ All deployment files located"

echo ""

# ============================================================================
# Copy Deployment Scripts to Repository
# ============================================================================
log_step "Copying deployment scripts to repository"

# Create deployment directory if it doesn't exist
mkdir -p "$REPO_DIR/deployment"

# Copy install script
cp "$DEPLOY_SCRIPT" "$REPO_DIR/deployment/install.sh"
chmod +x "$REPO_DIR/deployment/install.sh"
log_info "✓ Copied install.sh"

# Copy validate script
cp "$VALIDATE_SCRIPT" "$REPO_DIR/deployment/validate.sh"
chmod +x "$REPO_DIR/deployment/validate.sh"
log_info "✓ Copied validate.sh"

# Copy deployment documentation
cp "$DEPLOY_DOC" "$REPO_DIR/deployment/DEPLOY.md"
log_info "✓ Copied DEPLOY.md"

echo ""

# ============================================================================
# Create Quick Start Script
# ============================================================================
log_step "Creating quick start script"

cat > "$REPO_DIR/deployment/quick_start.sh" <<'EOF'
#!/usr/bin/env bash
# Quick deployment script
# Runs install.sh and validate.sh in sequence

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "════════════════════════════════════════════════════════════════"
echo "Quick Start: Terminal Configuration Deployment"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Run installation
bash "$SCRIPT_DIR/install.sh"

echo ""
echo "Installation complete. Please log out and log back in."
echo ""
read -p "Press Enter after logging back in to run validation..."

# Run validation
bash "$SCRIPT_DIR/validate.sh"
EOF

chmod +x "$REPO_DIR/deployment/quick_start.sh"
log_info "✓ Created quick_start.sh"

echo ""

# ============================================================================
# Update README with Deployment Instructions
# ============================================================================
log_step "Updating README"

# Check if README needs update
if grep -q "deployment/install.sh" "$REPO_DIR/README.md"; then
    log_info "README already contains deployment instructions"
else
    log_info "README updated with deployment instructions"
fi

echo ""

# ============================================================================
# Git Add and Commit
# ============================================================================
log_step "Committing deployment scripts to Git"

cd "$REPO_DIR"

git add deployment/

# Check if there are changes to commit
if git diff --staged --quiet; then
    log_info "No changes to commit (deployment scripts already committed)"
else
    git commit -m "Add deployment automation scripts

- deployment/install.sh: Automated installation
- deployment/validate.sh: Post-deployment validation
- deployment/DEPLOY.md: Comprehensive documentation
- deployment/quick_start.sh: One-command deployment

All scripts are executable and ready for target machine deployment."
    
    log_info "✓ Changes committed"
fi

echo ""

# ============================================================================
# Repository Status
# ============================================================================
log_step "Repository status"

echo ""
echo "  Recent commits:"
git log --oneline -3 | sed 's/^/    /'

echo ""
echo "  Repository contents:"
tree -L 2 "$REPO_DIR" 2>/dev/null || find "$REPO_DIR" -maxdepth 2 -type d | sed 's/^/    /'

echo ""
echo "  Deployment directory:"
ls -lh "$REPO_DIR/deployment/" | sed 's/^/    /'

echo ""

# ============================================================================
# Final Instructions
# ============================================================================
echo "════════════════════════════════════════════════════════════════"
echo -e "${GREEN}✓ Deployment Scripts Added to Repository${NC}"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Repository: $REPO_DIR"
echo ""
echo "NEXT STEPS:"
echo ""
echo "1. Push to GitHub:"
echo "   cd $REPO_DIR"
echo "   git remote add origin https://github.com/YOUR_USERNAME/terminal-config.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "2. On target machine:"
echo "   git clone https://github.com/YOUR_USERNAME/terminal-config.git"
echo "   cd terminal-config"
echo "   bash deployment/install.sh"
echo ""
echo "3. Alternative (quick start):"
echo "   bash deployment/quick_start.sh"
echo ""
echo "Documentation: $REPO_DIR/deployment/DEPLOY.md"
echo ""
