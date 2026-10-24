# Setup

Manual steps per OS. Omarchy and Ubuntu sections are still to be written.

## macOS

### New Mac

1. **Homebrew and base tools.** Puts Homebrew first on PATH and adds brew's zsh completions before oh-my-zsh runs
   `compinit`. eza comes from brew because it publishes no macOS builds; the other tools come from mise (step 4).

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> ~/.zprofile
   eval "$(/opt/homebrew/bin/brew shellenv zsh)"
   brew install git gh mise eza
   brew tap dloomorg/dloom https://github.com/dloomorg/dloom
   brew install dloomorg/dloom/dloom
   ```

2. **oh-my-zsh.** zsh is already the default shell. BSD sed needs the empty `-i ''`.

   ```sh
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
   git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
   git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
   sed -i '' 's/^plugins=(git)$/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
   ```

3. **Link the dotfiles.** `~/.gitconfig` has to be a real file first: when it's missing, `git config --global` writes
   into the linked `~/.config/git/config`, i.e. into this repo. Run dloom from the checkout; it reads
   `dloom/config.yaml` from the current directory.

   ```sh
   touch ~/.gitconfig
   git clone https://github.com/swaranga/dotfiles ~/Work/dotfiles/personal
   cd ~/Work/dotfiles/personal
   dloom link dloom shell zsh bash git ssh mise eza ghostty
   echo 'source ~/.config/zsh/.zshrc' >> ~/.zshrc
   echo 'source ~/.config/bash/.bashrc' >> ~/.bashrc
   ```

4. **Tools and JDKs.** `mise install` installs the pinned tools and the zulu JDKs (25 is the default; `java17`,
   `java21`, `java25` switch per shell). Registering the JDKs under `~/Library/Java/JavaVirtualMachines` lets
   `/usr/libexec/java_home`, Gradle and IntelliJ find them; the `zulu-NN` aliases keep the links valid across patch
   upgrades.

   ```sh
   mise install
   for v in 17 21 25; do
       mkdir -p ~/Library/Java/JavaVirtualMachines/zulu-$v.jdk
       ln -sfn ~/.local/share/mise/installs/java/zulu-$v/Contents ~/Library/Java/JavaVirtualMachines/zulu-$v.jdk/Contents
   done
   /usr/libexec/java_home -V
   ```

5. **Fonts.** Ghostty and Sublime use Consolas (ligaturized). It's licensed, so it isn't in this repo: copy the
   `.ttf` files from your private copy into `~/Library/Fonts`. macOS doesn't reliably pick up symlinked fonts.

6. **SSH key for github.com.** One key per machine, never copied. Start the machine-local `~/.ssh/config` with these
   lines, before any `Host` block; the keychain lines keep the key loaded across reboots, which signing needs:

   ```
   Include ~/.ssh/config.d/*

   Host *
     UseKeychain yes
     AddKeysToAgent yes
   ```

   Then create the key and upload it for authentication and signing:

   ```sh
   ssh-keygen -t ed25519 -C "$(hostname)" -f ~/.ssh/id_ed25519_github
   ssh-add --apple-use-keychain ~/.ssh/id_ed25519_github
   gh auth login -h github.com --scopes admin:public_key,admin:ssh_signing_key
   GH_HOST=github.com gh ssh-key add ~/.ssh/id_ed25519_github.pub --type authentication --title "$(hostname)"
   GH_HOST=github.com gh ssh-key add ~/.ssh/id_ed25519_github.pub --type signing --title "$(hostname)"
   ssh -T git@github.com    # Hi swaranga!
   git -C ~/Work/dotfiles/personal remote set-url origin git@github.com:swaranga/dotfiles.git
   ```

7. **Signing.** Turned on per machine in `~/.gitconfig`; the identity matched by the remote picks the key. Turn it
   on only once every identity you commit as has its key: a missing key makes those commits fail.

   ```sh
   git config --global commit.gpgSign true
   git config --global tag.gpgSign true
   ```

8. **Check.**

   ```sh
   git -C ~/Work/dotfiles/personal config user.email    # sarma.swaranga@gmail.com
   zsh -ic 'type gswitch'; bash -ic 'type gswitch'
   find ~/.config ~/.local ~/.ssh -type l ! -exec test -e {} \; -print    # dangling links: nothing
   ```

### Moving a Mac from the old dotfiles checkout

For a Mac set up from the old checkout: Homebrew and the step 1 tools, oh-my-zsh, the fonts and
`~/.ssh/id_ed25519_github` are already there, so steps 1, 2 and 5 above don't apply. The old checkout stays untouched
until the end, so any step can be undone by relinking from it. Keep a terminal open until a new one works.

1. **Back up** the current links and files (tar keeps symlinks as symlinks):

   ```sh
   tar -czf ~/dotfiles-before-switch.tgz -C ~ .gitconfig .ssh/config .config/git .config/mise .config/shell \
       .config/zsh .config/bash .config/dloom .config/ghostty .config/eza 2>/dev/null
   ```

2. **Make `~/.gitconfig` a real file,** then delete everything `~/.config/git/config` and the identity files now
   provide (user, email, signing key, aliases, core, pull, rerere, stash, excludesFile, credential). Keep only what's
   specific to this machine, such as blocks another tool maintains. Leave signing off until step 7 above.

   ```sh
   cp "$(readlink ~/.gitconfig)" ~/.gitconfig.new && mv ~/.gitconfig.new ~/.gitconfig
   ```

3. **Unlink the old packages,** from the old checkout so dloom reads that repo's config. dloom only removes links that
   point into that checkout. If it backed up a file when it first linked, it puts that file back; the next step
   replaces it again.

   ```sh
   old_checkout=$(readlink ~/.config/zsh/.zshrc); old_checkout=${old_checkout%/zsh/.config/zsh/*}
   cd "$old_checkout" && dloom unlink dloom shell zsh bash ghostty eza
   find ~ -maxdepth 4 -type l -lname "$old_checkout/*"    # should print nothing
   ```

4. **Link the new packages.** If `git --version` is older than 2.36, `brew install git` first: the identity includes
   need it. Then steps 3 and 4 above, without the `touch` and the `echo` lines (`~/.zshrc` and
   `~/.bashrc` already source those paths). dloom asks before replacing real files such as `~/.config/mise/config.toml`;
   answer yes, the originals go to `~/.dloom/backups`. The default JDK is now zulu 25.

5. **SSH:** put the `Include` line from step 6 first in `~/.ssh/config` and delete the old inline `Host github.com`
   block; `config.d/github.conf` replaces it. `ssh -T git@github.com` should still greet you.

6. **Check** in a new terminal (step 8). Commits stay unsigned until you set up signing, which can wait. The existing
   `~/.ssh/id_ed25519_github` is the key step 6 would create, so don't run `ssh-keygen` (it would overwrite the key
   GitHub knows) and skip the authentication upload. Add the keychain lines, run the `ssh-add` and the
   `--type signing` upload from step 6 (if gh is already logged in, first
   `gh auth refresh -h github.com -s admin:ssh_signing_key`), then step 7.

Afterwards brew's bat, fzf, zoxide, git-delta and difftastic are shadowed by mise's copies in the shell, and gnupg and
pinentry-mac go unused once signing uses ssh; `brew uninstall` them if you like.

To roll back: `dloom unlink` the new packages from `~/Work/dotfiles/personal`, `dloom link` the old ones from the old
checkout, and restore `~/.gitconfig` from the tarball.
