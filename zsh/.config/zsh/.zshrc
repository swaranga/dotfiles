# Sourced at the end of the machine-local ~/.zshrc (after oh-my-zsh). Shared with bash:
# init.sh loads everything, mise included.
source ~/.config/shell/init.sh

# Set up fzf key bindings and fuzzy completion (fzf comes from mise)
if command -v fzf > /dev/null 2>&1; then
    source <(fzf --zsh)
fi
