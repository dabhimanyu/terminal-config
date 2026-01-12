#!/usr/bin/env bash
# 00_preflight_check.sh
# Pre-flight validation of terminal environment state
# Run this BEFORE extraction to verify system integrity

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "════════════════════════════════════════════════════════════════"
echo "Terminal Environment Pre-Flight Validation"
echo "════════════════════════════════════════════════════════════════"
echo ""

# ============================================================================
# 1. Font Installation Verification
# ============================================================================
echo -e "${BLUE}1. Font Installation Status${NC}"

FONT_COUNT=$(fc-list | grep -i "JetBrains Mono" | wc -l)
echo "   Detected JetBrains Mono variants: $FONT_COUNT"

if [ $FONT_COUNT -gt 0 ]; then
    echo -e "   ${GREEN}✓${NC} Fonts present"
else
    echo -e "   ${RED}✗${NC} Fonts missing"
fi

echo ""

# ============================================================================
# 2. Font File Locations
# ============================================================================
echo -e "${BLUE}2. Font File Locations${NC}"

FONT_FILES=$(find ~/.local/share/fonts -name "JetBrainsMono*.ttf" -type f 2>/dev/null | wc -l)
echo "   Total JetBrains Mono .ttf files: $FONT_FILES"

if [ $FONT_FILES -gt 0 ]; then
    echo "   First 5 file paths:"
    find ~/.local/share/fonts -name "JetBrainsMono*.ttf" -type f 2>/dev/null | head -5 | sed 's/^/      /'
    echo -e "   ${GREEN}✓${NC} Font files accessible"
else
    echo -e "   ${YELLOW}⚠${NC} No .ttf files found in ~/.local/share/fonts"
fi

echo ""

# ============================================================================
# 3. GNOME Terminal Profile Inventory
# ============================================================================
echo -e "${BLUE}3. GNOME Terminal Profiles${NC}"

# Get default profile UUID
DEFAULT_UUID=$(dconf read /org/gnome/terminal/legacy/profiles:/default 2>/dev/null | tr -d "'")

if [ -n "$DEFAULT_UUID" ]; then
    echo "   Default Profile UUID: $DEFAULT_UUID"
    
    # Get profile details
    PROFILE_NAME=$(dconf read "/org/gnome/terminal/legacy/profiles:/:$DEFAULT_UUID/visible-name" 2>/dev/null | tr -d "'")
    FONT=$(dconf read "/org/gnome/terminal/legacy/profiles:/:$DEFAULT_UUID/font" 2>/dev/null | tr -d "'")
    USE_SYSTEM_FONT=$(dconf read "/org/gnome/terminal/legacy/profiles:/:$DEFAULT_UUID/use-system-font" 2>/dev/null)
    
    echo "   Profile Name: $PROFILE_NAME"
    echo "   Font Setting: $FONT"
    echo "   Uses System Font: $USE_SYSTEM_FONT"
    echo -e "   ${GREEN}✓${NC} Default profile configured"
else
    echo -e "   ${RED}✗${NC} No default profile found"
fi

echo ""

# Get all profile UUIDs
echo "   All Available Profiles:"
PROFILE_LIST=$(dconf list /org/gnome/terminal/legacy/profiles:/ 2>/dev/null | grep ':' | tr -d ':/')

if [ -n "$PROFILE_LIST" ]; then
    PROFILE_COUNT=0
    while IFS= read -r UUID; do
        if [ -n "$UUID" ]; then
            PROFILE_COUNT=$((PROFILE_COUNT + 1))
            NAME=$(dconf read "/org/gnome/terminal/legacy/profiles:/:$UUID/visible-name" 2>/dev/null | tr -d "'")
            if [ "$UUID" = "$DEFAULT_UUID" ]; then
                echo "      [$PROFILE_COUNT] $UUID - \"$NAME\" [DEFAULT]"
            else
                echo "      [$PROFILE_COUNT] $UUID - \"$NAME\""
            fi
        fi
    done <<< "$PROFILE_LIST"
    
    echo -e "   ${GREEN}✓${NC} Total profiles detected: $PROFILE_COUNT"
else
    echo -e "   ${YELLOW}⚠${NC} No profiles found"
fi

echo ""

# ============================================================================
# 4. Shell Configuration Files
# ============================================================================
echo -e "${BLUE}4. Shell Configuration Files${NC}"

for file in .zshrc .bashrc .shell_common; do
    if [ -f "$HOME/$file" ]; then
        FILE_SIZE=$(stat -f%z "$HOME/$file" 2>/dev/null || stat -c%s "$HOME/$file" 2>/dev/null)
        echo -e "   ${GREEN}✓${NC} $file present (${FILE_SIZE} bytes)"
    else
        echo -e "   ${RED}✗${NC} $file missing"
    fi
done

echo ""

# ============================================================================
# 5. Oh-My-Zsh Framework
# ============================================================================
echo -e "${BLUE}5. Oh-My-Zsh Framework${NC}"

if [ -d ~/.oh-my-zsh ]; then
    echo -e "   ${GREEN}✓${NC} Framework directory exists"
    
    if [ -f ~/.oh-my-zsh/oh-my-zsh.sh ]; then
        echo -e "   ${GREEN}✓${NC} Core script present"
    else
        echo -e "   ${RED}✗${NC} Core script missing"
    fi
    
    # Check theme
    if [ -d ~/.oh-my-zsh/themes ]; then
        THEME_COUNT=$(ls ~/.oh-my-zsh/themes/*.zsh-theme 2>/dev/null | wc -l)
        echo "   Themes available: $THEME_COUNT"
    fi
else
    echo -e "   ${RED}✗${NC} Oh-My-Zsh not installed"
fi

echo ""

# ============================================================================
# 6. Oh-My-Zsh Plugins
# ============================================================================
echo -e "${BLUE}6. Oh-My-Zsh Plugins${NC}"

PLUGIN_DIR="$HOME/.oh-my-zsh/custom/plugins"

if [ -d "$PLUGIN_DIR" ]; then
    echo "   Custom plugins directory: exists"
    
    if [ -d "$PLUGIN_DIR/zsh-autosuggestions" ]; then
        echo -e "   ${GREEN}✓${NC} zsh-autosuggestions installed"
    else
        echo -e "   ${YELLOW}⚠${NC} zsh-autosuggestions not found"
    fi
    
    if [ -d "$PLUGIN_DIR/zsh-syntax-highlighting" ]; then
        echo -e "   ${GREEN}✓${NC} zsh-syntax-highlighting installed"
    else
        echo -e "   ${YELLOW}⚠${NC} zsh-syntax-highlighting not found"
    fi
else
    echo -e "   ${YELLOW}⚠${NC} Custom plugins directory does not exist"
fi

echo ""

# ============================================================================
# 7. Path-Dependent Aliases Detection
# ============================================================================
echo -e "${BLUE}7. Path-Dependent Aliases in .shell_common${NC}"

if [ -f ~/.shell_common ]; then
    echo "   Detected aliases:"
    grep "^alias" ~/.shell_common 2>/dev/null | while IFS= read -r line; do
        echo "      $line"
    done
    echo ""
    echo -e "   ${YELLOW}⚠${NC} These paths must be verified on target machine"
else
    echo -e "   ${RED}✗${NC} .shell_common not found"
fi

echo ""

# ============================================================================
# 8. System Information
# ============================================================================
echo -e "${BLUE}8. System Information${NC}"

echo "   Hostname: $(hostname)"
echo "   Username: $USER"
echo "   OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")"
echo "   Kernel: $(uname -r)"
echo "   Default Shell: $SHELL"
echo "   Zsh Version: $(zsh --version 2>/dev/null || echo "Not installed")"

echo ""

# ============================================================================
# Summary
# ============================================================================
echo "════════════════════════════════════════════════════════════════"
echo -e "${GREEN}Pre-Flight Validation Complete${NC}"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "NEXT STEP: If all checks passed, run 01_extract_config.sh"
echo ""
