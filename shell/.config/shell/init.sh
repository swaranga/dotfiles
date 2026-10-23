# The only file the rc files source. lib.sh first, the rest depend on it.
source ~/.config/shell/lib.sh
source ~/.config/shell/common.sh
source ~/.config/shell/git.sh
# Overlays and untracked per-host files drop in here; this repo never names them.
# *.sh load in both shells, *.zsh / *.bash only in that shell, in lexical order.
__sh_source_dir ~/.config/shell/conf.d
