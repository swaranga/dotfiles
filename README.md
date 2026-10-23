# dotfiles

Shell, git, tool and desktop config for my machines (Omarchy, macOS, Ubuntu), linked into `$HOME` with
[dloom](https://github.com/dloomorg/dloom). Each top-level directory is a package whose contents mirror `$HOME`.

```sh
git clone https://github.com/swaranga/dotfiles ~/Work/dotfiles/personal
cd ~/Work/dotfiles/personal                           # dloom reads dloom/config.yaml from here
dloom link shell zsh bash git ssh mise eza ghostty    # plus hyprland on Omarchy
mise install
```

These stay machine-local and are never linked:

- `~/.zshrc` / `~/.bashrc`: end with `source ~/.config/zsh/.zshrc` / `source ~/.config/bash/.bashrc`.
- `~/.gitconfig`: signing (`commit.gpgSign`) and whatever tools write there. Keep it a real file, otherwise
  `git config --global` writes into the linked `~/.config/git/config`.
- `~/.ssh/config`: starts with `Include ~/.ssh/config.d/*`.

## Extension points

- `~/.config/shell/conf.d/`: `*.sh` load in both shells, `*.zsh` / `*.bash` only in that one, in lexical order.
- `~/.config/git/overlay.gitconfig`: included last, so identities it adds win.

## Keep it generic

This repo is public. Anything tied to an employer, a client or a private network belongs in a separate private
overlay that uses the extension points above. Check new files for internal host names, tool names and email
addresses before pushing.
