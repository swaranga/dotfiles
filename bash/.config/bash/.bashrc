# Sourced at the end of the machine-local ~/.bashrc. Runs under the stock macOS bash 3.2
# (/bin/bash) unless a Homebrew bash is installed, so the shared files must not rely on
# bash 4+ features.
source ~/.config/shell/init.sh

# Set up fzf key bindings and fuzzy completion (fzf comes from mise)
if command -v fzf > /dev/null 2>&1; then
    eval "$(fzf --bash)"
fi
