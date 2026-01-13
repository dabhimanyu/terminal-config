# ~/.zshrc - Research Environment (Zsh 5.8+)
# FINAL VERSION - Pyenv + NVM support

# ============================================================================
# CRITICAL: PYENV INITIALIZATION (MUST come BEFORE oh-my-zsh)
# ============================================================================
# Reason: oh-my-zsh's 'python' plugin wraps pyenv as a function.
# If sourced AFTER oh-my-zsh loads, the plugin caches old PATH without pyenv shims.
# Solution: Initialize pyenv FIRST, so oh-my-zsh sees pyenv shims in PATH.
#
# CRITICAL FIX: We also REMOVE the 'python' plugin from oh-my-zsh (see below)
# because it creates a function wrapper that bypasses PATH resolution entirely.
# ============================================================================
export PYENV_ROOT="$HOME/.pyenv"

# Only add to PATH if not already present (prevent duplication)
if [[ ":$PATH:" != *":$PYENV_ROOT/bin:"* ]]; then
    export PATH="$PYENV_ROOT/bin:$PATH"
fi

eval "$(pyenv init - zsh)"
eval "$(pyenv virtualenv-init -)"

# ============================================================================
# NVM INITIALIZATION (For Claude Code, Gemini CLI, Node.js tooling)
# ============================================================================
# NVM must initialize AFTER pyenv but BEFORE oh-my-zsh to ensure proper PATH order
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ============================================================================
# Framework Initialization (oh-my-zsh)
# ============================================================================
export ZSH="$HOME/.oh-my-zsh"

# CRITICAL FIX: REMOVED 'python' from plugins list
# Reason: The python plugin creates a function wrapper that calls 'pyenv exec python',
# which ignores PATH order and uses .python-version files instead.
# This breaks the expected behavior where 'which python' returns the shim path.
#
# OLD: plugins=(git python pip virtualenv ...)
# NEW: plugins=(git pip virtualenv ...)  ← 'python' removed
plugins=(
    git
    pip
    virtualenv
    command-not-found
    colored-man-pages
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# ============================================================================
# Theme & Prompt
# ============================================================================
# Custom prompt with virtualenv indicator (if active)
ZSH_THEME_VIRTUALENV_PREFIX="("
ZSH_THEME_VIRTUALENV_SUFFIX=") "

# Format: [exit_code_indicator] [venv_if_active] current_dir
PROMPT="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ ) %{$fg_bold[blue]%}\$(virtualenv_prompt_info)%{$fg[cyan]%}%c%{$reset_color%} "

# ============================================================================
# Shell History Configuration
# ============================================================================
HISTSIZE=1000
SAVEHIST=2000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE APPEND_HISTORY SHARE_HISTORY

# ============================================================================
# Single Source of Truth: Load .shell_common (aliases, PATH, virtualenv)
# ============================================================================
# .shell_common contains: aliases, PATH additions, virtualenv settings.
# Sourced LAST, after all framework initialization is complete.
[ -f ~/.shell_common ] && source ~/.shell_common

# End of .zshrc