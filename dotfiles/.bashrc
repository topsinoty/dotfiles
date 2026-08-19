if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

for directory in "$HOME/bin" "$HOME/.local/bin"; do
    case :$PATH: in
        *:"$directory":*) ;;
        *) PATH=$directory:$PATH ;;
    esac
done
unset directory
export PATH
export EDITOR=nano

HISTFILE=$HOME/.bash_history
HISTSIZE=100000
HISTFILESIZE=100000
shopt -s histappend

if [ -d "$HOME/.bashrc.d" ]; then
    for fragment in "$HOME"/.bashrc.d/*; do
        [ -r "$fragment" ] && . "$fragment"
    done
    unset fragment
fi

command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"
command -v fzf >/dev/null 2>&1 && eval "$(fzf --bash)"
command -v mise >/dev/null 2>&1 && eval "$(mise activate bash)"

dotfiles_history_sync()
{
    history -a
    history -n
}

case $(declare -p PROMPT_COMMAND 2>/dev/null) in
    "declare -a"*) PROMPT_COMMAND+=(dotfiles_history_sync) ;;
    *) PROMPT_COMMAND="dotfiles_history_sync${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
esac
