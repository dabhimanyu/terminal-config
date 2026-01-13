#!/usr/bin/env bash
# deployment/validate.sh
# Post-deployment validation script
# Verifies all components installed correctly

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
info() { echo -e "${BLUE}ℹ${NC} $1"; }

FAIL_COUNT=0
WARN_COUNT=0

echo "════════════════════════════════════════════════════════════════"
echo "Terminal Environment Validation"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Target User: $USER"
echo "Target Hostname: $(hostname)"
echo "Validation Time: $(date)"
echo ""

# ============================================================================
# 1. Default Shell Verification
# ============================================================================
echo "1. Default Shell"
CURRENT_SHELL=$(basename "$SHELL")

if [ "$CURRENT_SHELL" = "zsh" ]; then
    pass "Zsh is default shell"
    info "Shell path: $SHELL"
    info "Zsh version: $(zsh --version 2>/dev/null)"
else
    fail "Default shell is $CURRENT_SHELL (expected: zsh)"
    warn "Run: chsh -s \$(which zsh), then log out and log back in"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo ""

# ============================================================================
# 2. Configuration Files Verification
# ============================================================================
echo "2. Configuration Files"

for file in .zshrc .bashrc .shell_common; do
    if [ -f "$HOME/$file" ]; then
        FILE_SIZE=$(stat -c%s "$HOME/$file" 2>/dev/null || stat -f%z "$HOME/$file" 2>/dev/null)
        pass "$file present (${FILE_SIZE} bytes)"
    else
        fail "$file missing"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done

# Check if .zshrc sources .shell_common
if [ -f ~/.zshrc ]; then
    if grep -q "shell_common" ~/.zshrc; then
        pass ".zshrc sources .shell_common"
    else
        warn ".zshrc does not source .shell_common"
        WARN_COUNT=$((WARN_COUNT + 1))
    fi
fi

echo ""

# ============================================================================
# 3. Oh-My-Zsh Framework Verification
# ============================================================================
echo "3. Oh-My-Zsh Framework"

if [ -d ~/.oh-my-zsh ]; then
    pass "Framework directory exists"
    
    if [ -f ~/.oh-my-zsh/oh-my-zsh.sh ]; then
        pass "Core script present"
    else
        fail "Core script missing"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
    
    # Check themes
    if [ -d ~/.oh-my-zsh/themes ]; then
        THEME_COUNT=$(ls ~/.oh-my-zsh/themes/*.zsh-theme 2>/dev/null | wc -l)
        pass "Themes directory present ($THEME_COUNT themes)"
    else
        warn "Themes directory missing"
        WARN_COUNT=$((WARN_COUNT + 1))
    fi
else
    fail "Oh-My-Zsh framework not installed"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo ""

# ============================================================================
# 4. Plugin Verification
# ============================================================================
echo "4. Oh-My-Zsh Plugins"

PLUGIN_DIR="$HOME/.oh-my-zsh/custom/plugins"

if [ -d "$PLUGIN_DIR" ]; then
    pass "Custom plugins directory exists"
    
    # zsh-autosuggestions
    if [ -d "$PLUGIN_DIR/zsh-autosuggestions" ]; then
        if [ -f "$PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
            pass "zsh-autosuggestions installed"
        else
            fail "zsh-autosuggestions directory exists but script missing"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    else
        fail "zsh-autosuggestions not installed"
        warn "Run: git clone https://github.com/zsh-users/zsh-autosuggestions.git $PLUGIN_DIR/zsh-autosuggestions"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
    
    # zsh-syntax-highlighting
    if [ -d "$PLUGIN_DIR/zsh-syntax-highlighting" ]; then
        if [ -f "$PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
            pass "zsh-syntax-highlighting installed"
        else
            fail "zsh-syntax-highlighting directory exists but script missing"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    else
        fail "zsh-syntax-highlighting not installed"
        warn "Run: git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $PLUGIN_DIR/zsh-syntax-highlighting"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
    
    # Check if plugins are enabled in .zshrc
    if [ -f ~/.zshrc ]; then
        if grep -q "zsh-autosuggestions" ~/.zshrc && grep -q "zsh-syntax-highlighting" ~/.zshrc; then
            pass "Plugins enabled in .zshrc"
        else
            warn "Plugins may not be enabled in .zshrc"
            WARN_COUNT=$((WARN_COUNT + 1))
        fi
    fi
else
    warn "Custom plugins directory does not exist"
    WARN_COUNT=$((WARN_COUNT + 1))
fi

echo ""

# ============================================================================
# 5. Font Installation Verification
# ============================================================================
echo "5. JetBrains Mono Font"

FONT_COUNT=$(fc-list | grep -i "JetBrains Mono" | wc -l)

if [ $FONT_COUNT -gt 0 ]; then
    pass "Font installed ($FONT_COUNT variants detected)"
    
    # Show sample of installed variants
    info "Sample variants:"
    fc-list | grep -i "JetBrains Mono" | head -3 | sed 's/^/     /'
else
    fail "JetBrains Mono font NOT installed"
    warn "Fonts should have been installed by deployment script"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Check font files
FONT_FILES=$(find ~/.local/share/fonts -name "JetBrainsMono*.ttf" -type f 2>/dev/null | wc -l)
if [ $FONT_FILES -gt 0 ]; then
    pass "Font files present in ~/.local/share/fonts ($FONT_FILES files)"
else
    warn "No JetBrains Mono .ttf files found in ~/.local/share/fonts"
    WARN_COUNT=$((WARN_COUNT + 1))
fi

echo ""

# ============================================================================
# 6. GNOME Terminal Profile Verification
# ============================================================================
echo "6. GNOME Terminal Profiles"

if command -v dconf &> /dev/null; then
    # Check if profiles exist
    PROFILE_LIST=$(dconf list /org/gnome/terminal/legacy/profiles:/ 2>/dev/null | grep ':' | tr -d ':/')
    
    if [ -n "$PROFILE_LIST" ]; then
        PROFILE_COUNT=$(echo "$PROFILE_LIST" | wc -l)
        pass "Profiles detected ($PROFILE_COUNT profiles)"
        
        # Check default profile
        DEFAULT_UUID=$(dconf read /org/gnome/terminal/legacy/profiles:/default 2>/dev/null | tr -d "'")
        if [ -n "$DEFAULT_UUID" ]; then
            DEFAULT_NAME=$(dconf read "/org/gnome/terminal/legacy/profiles:/:$DEFAULT_UUID/visible-name" 2>/dev/null | tr -d "'")
            pass "Default profile set: \"$DEFAULT_NAME\""
            
            # Check font setting
            CUSTOM_FONT=$(dconf read "/org/gnome/terminal/legacy/profiles:/:$DEFAULT_UUID/use-system-font" 2>/dev/null)
            if [ "$CUSTOM_FONT" = "false" ]; then
                FONT=$(dconf read "/org/gnome/terminal/legacy/profiles:/:$DEFAULT_UUID/font" 2>/dev/null | tr -d "'")
                pass "Custom font enabled: $FONT"
            else
                warn "System font in use (custom font not enabled)"
                info "To enable: Terminal → Preferences → Text → Check 'Custom font'"
                WARN_COUNT=$((WARN_COUNT + 1))
            fi
            
            # Check colors
            USE_THEME_COLORS=$(dconf read "/org/gnome/terminal/legacy/profiles:/:$DEFAULT_UUID/use-theme-colors" 2>/dev/null)
            if [ "$USE_THEME_COLORS" = "false" ]; then
                pass "Custom colors enabled"
            else
                info "Theme colors in use"
            fi
        else
            warn "No default profile set"
            WARN_COUNT=$((WARN_COUNT + 1))
        fi
    else
        warn "No profiles found"
        WARN_COUNT=$((WARN_COUNT + 1))
    fi
else
    fail "dconf not available (cannot verify profiles)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo ""

# ============================================================================
# 7. Path-Dependent Aliases Check
# ============================================================================
echo "7. Path-Dependent Aliases"

if [ -f ~/.shell_common ]; then
    ALIAS_COUNT=$(grep "^alias" ~/.shell_common 2>/dev/null | wc -l)
    
    if [ $ALIAS_COUNT -gt 0 ]; then
        info "Detected $ALIAS_COUNT aliases in .shell_common"
        echo ""
        info "Manual verification required for these paths:"
        grep "^alias" ~/.shell_common | while IFS= read -r line; do
            echo "     $line"
        done
        echo ""
        warn "⚠ Update paths in ~/.shell_common if they differ on this system"
        WARN_COUNT=$((WARN_COUNT + 1))
    else
        info "No aliases found in .shell_common"
    fi
else
    fail ".shell_common not found"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo ""

# ============================================================================
# 8. Zsh Functionality Test
# ============================================================================
echo "8. Zsh Functionality"

if [ -n "$ZSH_VERSION" ]; then
    pass "Running in Zsh (version: $ZSH_VERSION)"
    
    # Check if Oh-My-Zsh is loaded
    if [ -n "$ZSH" ]; then
        pass "Oh-My-Zsh loaded (ZSH=$ZSH)"
    else
        warn "Oh-My-Zsh environment variable not set"
        WARN_COUNT=$((WARN_COUNT + 1))
    fi
else
    warn "Not running in Zsh (current shell: $SHELL)"
    info "Zsh features cannot be tested in this session"
    WARN_COUNT=$((WARN_COUNT + 1))
fi

echo ""

# ============================================================================
# 9. Environment Variables Check
# ============================================================================
echo "9. Environment Variables"

# Check PATH
if echo "$PATH" | grep -q "$HOME/.local/bin"; then
    pass "~/.local/bin in PATH"
else
    warn "~/.local/bin not in PATH"
    WARN_COUNT=$((WARN_COUNT + 1))
fi

if echo "$PATH" | grep -q "$HOME/bin"; then
    pass "~/bin in PATH"
else
    info "~/bin not in PATH (may not exist)"
fi

echo ""

# ============================================================================
# 10. Version Manager Verification (Optional)
# ============================================================================
echo "10. Version Managers (Optional)"

# Pyenv verification
if command -v pyenv &> /dev/null; then
    pass "Pyenv installed"
    PYENV_VERSION=$(pyenv --version 2>/dev/null | cut -d' ' -f2)
    info "Pyenv version: $PYENV_VERSION"

    # Check if pyenv is in PATH
    if echo "$PATH" | grep -q "pyenv/shims"; then
        pass "Pyenv shims in PATH"
    else
        warn "Pyenv shims not in PATH (check .zshrc/.bashrc initialization)"
        WARN_COUNT=$((WARN_COUNT + 1))
    fi

    # Check for installed Python versions
    PYTHON_VERSIONS=$(pyenv versions --bare 2>/dev/null | wc -l)
    if [ $PYTHON_VERSIONS -gt 0 ]; then
        info "Python versions installed via pyenv: $PYTHON_VERSIONS"
    else
        info "No Python versions installed via pyenv yet"
    fi
else
    info "Pyenv not installed (optional - install with: curl https://pyenv.run | bash)"
fi

# NVM verification
if [ -d "$HOME/.nvm" ]; then
    pass "NVM directory exists"

    # Check if nvm command is available (requires sourcing)
    if command -v nvm &> /dev/null || [ -n "$NVM_DIR" ]; then
        pass "NVM initialized"

        # Try to get NVM version (requires bash/zsh context)
        if command -v nvm &> /dev/null; then
            NVM_VERSION=$(nvm --version 2>/dev/null || echo "unknown")
            info "NVM version: $NVM_VERSION"

            # Check for installed Node versions
            NODE_VERSIONS=$(nvm list 2>/dev/null | grep -c "v[0-9]" || echo 0)
            if [ "$NODE_VERSIONS" -gt 0 ]; then
                info "Node.js versions installed via NVM: $NODE_VERSIONS"
            else
                info "No Node.js versions installed via NVM yet"
            fi
        fi
    else
        warn "NVM not initialized (may require new shell session)"
        WARN_COUNT=$((WARN_COUNT + 1))
    fi
else
    info "NVM not installed (optional - install with: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash)"
fi

echo ""
info "Note: Version managers are optional. Shell configs gracefully skip initialization if not present."

echo ""

# ============================================================================
# 11. Backup Files Check
# ============================================================================
echo "11. Backup Files"

BACKUP_COUNT=$(find ~ -maxdepth 1 -name "*.pre-migration*" 2>/dev/null | wc -l)

if [ $BACKUP_COUNT -gt 0 ]; then
    info "Found $BACKUP_COUNT backup files from migration:"
    find ~ -maxdepth 1 -name "*.pre-migration*" 2>/dev/null | sed 's/^/     /' | head -5
    if [ $BACKUP_COUNT -gt 5 ]; then
        echo "     ... and $((BACKUP_COUNT - 5)) more"
    fi
    echo ""
    info "These can be safely deleted after confirming everything works"
else
    info "No backup files found"
fi

echo ""

# ============================================================================
# Summary
# ============================================================================
echo "════════════════════════════════════════════════════════════════"
echo "Validation Summary"
echo "════════════════════════════════════════════════════════════════"
echo ""

if [ $FAIL_COUNT -eq 0 ] && [ $WARN_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ ALL CHECKS PASSED${NC}"
    echo ""
    echo "Terminal environment successfully deployed!"
    EXIT_CODE=0
elif [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${YELLOW}⚠ PASSED WITH WARNINGS${NC}"
    echo ""
    echo "Total warnings: $WARN_COUNT"
    echo "These are typically minor issues or manual steps required."
    EXIT_CODE=0
else
    echo -e "${RED}✗ VALIDATION FAILED${NC}"
    echo ""
    echo "Total failures: $FAIL_COUNT"
    echo "Total warnings: $WARN_COUNT"
    echo ""
    echo "Please address the failed checks above."
    EXIT_CODE=1
fi

echo ""
echo "NEXT STEPS:"
echo ""

if [ "$CURRENT_SHELL" != "zsh" ]; then
    echo "1. Log out and log back in to activate Zsh"
fi

if [ $WARN_COUNT -gt 0 ]; then
    echo "2. Review warnings and update as needed"
    echo "   - Verify paths in ~/.shell_common"
    echo "   - Enable custom font in Terminal preferences"
fi

echo "3. Test functionality:"
echo "   - Open new terminal → Check prompt and colors"
echo "   - Type commands → Verify syntax highlighting"
echo "   - Start typing → Verify gray autosuggestions"
echo "   - Check font → Terminal → Preferences → Text"
echo ""

exit $EXIT_CODE
