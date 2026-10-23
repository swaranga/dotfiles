# Shared by every other file in this directory, so it has to be sourced FIRST.
# Everything here exists only to paper over the handful of places where zsh and
# bash genuinely disagree; if something works the same in both, it does not
# belong in this file.

# Which shell is running us. Sniffed once here so the rest of the config can
# branch on it instead of re-testing $ZSH_VERSION everywhere. Deliberately not
# exported -- child processes have their own shell.
if [ -n "${ZSH_VERSION:-}" ]; then
    __SH_KIND=zsh
elif [ -n "${BASH_VERSION:-}" ]; then
    __SH_KIND=bash
else
    __SH_KIND=unknown
fi

# Print the Nth element (1-based) of the arguments; returns 1 if N is out of
# range. Arrays are 1-based in zsh but 0-based in bash, so "${arr[2]}" means
# different things in each. Positional parameters are 1-based in both, hence
# this detour: __sh_nth 2 "${arr[@]}".
__sh_nth() {
    local n=$1
    shift
    [ "$n" -ge 1 ] && [ "$n" -le $# ] || return 1
    shift $((n - 1))
    printf '%s\n' "$1"
}

# Single-key y/N prompt; returns 0 only for y or Y. zsh spells this `read -q`
# and bash spells it `read -n 1`, and neither accepts the other's flags.
__sh_confirm() {
    local __reply=""
    if [ "$__SH_KIND" = zsh ]; then
        read -k 1 "__reply?$1"
    else
        read -r -n 1 -p "$1" __reply
    fi
    printf '\n'
    case "$__reply" in
        y|Y) return 0 ;;
        *) return 1 ;;
    esac
}
