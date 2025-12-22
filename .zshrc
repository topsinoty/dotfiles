autoload -Uz compinit
compinit -i -C
setopt COMPLETE_IN_WORD

HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

source <(fzf --zsh)
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8' 
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

eval "$(mise activate zsh)"

EDITOR="micro"
# add jetbrains toolbox....not manually upgradable
export PATH="$HOME/Applications/jetbrains-toolbox-3.2.0.65851/bin:$PATH"
