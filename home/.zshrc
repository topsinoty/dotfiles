autoload -Uz compinit
compinit -i -C
setopt COMPLETE_IN_WORD

zmodload zsh/terminfo
if [[ -n ${terminfo[kdch1]} ]]; then
    bindkey "${terminfo[kdch1]}" delete-char
fi

HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY
setopt SHARE_HISTORY

command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v fzf >/dev/null 2>&1 && source <(fzf --zsh)
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"

export EDITOR=nano
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

if [ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if [ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
