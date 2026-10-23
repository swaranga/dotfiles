# prevent breaking ghostty to being treated weirdly when sshing into a machine
export TERM=xterm-256color
# free ctrl-s from XOFF flow control so it works as a key binding (gs staging).
# guarded because stty errors out when stdin is not a terminal.
[[ -t 0 ]] && stty -ixon
# Commands too boring to keep in history. Same list, two spellings: zsh wants a
# single alternation pattern, bash wants colon-separated globs.
if [ "$__SH_KIND" = zsh ]; then
    export HISTORY_IGNORE="(ls|cd|cdi|pwd|exit|sudo reboot|history|cd -|cd ..)"
else
    export HISTIGNORE="ls:cd:cdi:pwd:exit:sudo reboot:history:cd -:cd .."
fi

### PATH
if [ -d "$HOME/.bin" ] ;
  then PATH="$HOME/.bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ] ;
  then PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "$HOME/.cargo/bin" ] ;
  then PATH="$HOME/.cargo/bin:$PATH"
fi

if [ -d "/usr/local/go/bin" ] ;
  then PATH="/usr/local/go/bin:$PATH"
fi

if [ -z "$XDG_CONFIG_HOME" ] ; then
    export XDG_CONFIG_HOME="$HOME/.config"
fi
if [ -z "$XDG_DATA_HOME" ] ; then
    export XDG_DATA_HOME="$HOME/.local/share"
fi

# mise (JDKs, node, fzf, eza, zoxide, ...). After the PATH entries above so its tools come
# first, and before the `command -v` checks below so they can see what it provides.
if command -v mise > /dev/null 2>&1; then
    eval "$(mise activate "$__SH_KIND")"
fi

# set eza config directory
export EZA_CONFIG_DIR=~/.config/eza

if command -v eza > /dev/null 2>&1; then
    alias ls="eza --icons --group-directories-first"
    alias ll="eza --icons --group-directories-first -lh"
fi
alias tsup="sudo tailscale up --netfilter-mode=nodivert --ssh"
alias tsdown="sudo tailscale down"
# alias bat="batcat"

# gradle aliases. An overlay can set GRCB_EXTRA_ARGS to add one flag to grcb (a single
# word: zsh doesn't split it).
alias grw="./gradlew"
alias grc="./gradlew clean"
alias grb="./gradlew build"
alias grcb='./gradlew clean cleanTest build -Porg.gradle.caching=false --no-build-cache $GRCB_EXTRA_ARGS'
alias grbr="./gradlew bootRun"
alias grl="./gradlew generateLock saveLock"

# Unix aliases
alias grep="grep --color"
alias tailf="tail -f"

# Switch the JDK for this shell only (mise is activated above)
alias java17='mise shell java@zulu-17'
alias java21='mise shell java@zulu-21'
alias java25='mise shell java@zulu-25'
alias javaoff='mise shell --unset java'

function extract {
 if [ -z "$1" ]; then
    # display usage if no parameters given
    echo "Usage: extract <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
    echo "       extract <path/file_name_1.ext> [path/file_name_2.ext] [path/file_name_3.ext]"
 else
    for n in "$@"
    do
      if [ -f "$n" ] ; then
          case "${n%,}" in
            *.cbt|*.tar.bz2|*.tar.gz|*.tar.xz|*.tbz2|*.tgz|*.txz|*.tar)
                         tar xvf "$n"       ;;
            *.lzma)      unlzma ./"$n"      ;;
            *.bz2)       bunzip2 ./"$n"     ;;
            *.cbr|*.rar)       unrar x -ad ./"$n" ;;
            *.gz)        gunzip ./"$n"      ;;
            *.cbz|*.epub|*.zip)       unzip ./"$n"       ;;
            *.z)         uncompress ./"$n"  ;;
            *.7z|*.arj|*.cab|*.cb7|*.chm|*.deb|*.dmg|*.iso|*.lzh|*.msi|*.pkg|*.rpm|*.udf|*.wim|*.xar)
                         7z x ./"$n"        ;;
            *.xz)        unxz ./"$n"        ;;
            *.exe)       cabextract ./"$n"  ;;
            *.cpio)      cpio -id < ./"$n"  ;;
            *.cba|*.ace)      unace x ./"$n"      ;;
            *)
                         echo "extract: '$n' - unknown archive method"
                         return 1
                         ;;
          esac
      else
          echo "'$n' - file does not exist"
          return 1
      fi
    done
fi
}

# zoxide shadows cd, so it stays last -- and it has to be told which shell it is
# generating glue code for.
if command -v zoxide > /dev/null 2>&1; then
    eval "$(zoxide init --cmd cd "$__SH_KIND")"
fi
