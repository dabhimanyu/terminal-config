# ~/.zshrc - Research Environment
export ZSH="$HOME/.oh-my-zsh"

# 1. Framework Initialization
# We use the plugins to handle the heavy lifting (git, virtualenv)
plugins=(git python pip virtualenv command-not-found colored-man-pages zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# 2. Single Theme Definition (RobbyRussell + VirtualEnv Hook)
# We override the default RobbyRussell prompt here to add the space and the env tag
ZSH_THEME_VIRTUALENV_PREFIX="("
ZSH_THEME_VIRTUALENV_SUFFIX=") "

PROMPT="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ ) %{$fg_bold[blue]%}\$(virtualenv_prompt_info)%{$fg[cyan]%}%c%{$reset_color%} "

# 3. Standard Shell Operations
HISTSIZE=1000
SAVEHIST=2000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE APPEND_HISTORY SHARE_HISTORY

# 4. Single Source of Truth Linkage
[ -f ~/.shell_common ] && source ~/.shell_common
