# git aliases
alias gstat="git status"
alias glog="git log -n 5"
alias gcm="git commit -m"
alias glg="git log --graph --abbrev-commit --decorate --date=relative --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' -n 30 --all"
alias gamend="git commit --amend"

alias branches="git branch -v"
alias remotes="git remote -v"

export GPATCH_DIR="${HOME}/.git-patches"

function gpatch-create() {
    # Ensure patch directory exists
    mkdir -p "$GPATCH_DIR"

    # Get list of changed files (both staged and unstaged)
    local changed_files
    changed_files=$(git diff --name-only HEAD 2>/dev/null)

    if [[ -z "$changed_files" ]]; then
        echo "No changes to create a patch from."
        return 1
    fi

    # Use fzf to select files (multi-select with tab)
    local selected_files
    selected_files=$(echo "$changed_files" | fzf --multi --preview 'git diff HEAD -- {}' --preview-window=right:60%:wrap --header="Select files (TAB
to multi-select, ENTER to confirm)")

    if [[ -z "$selected_files" ]]; then
        echo "No files selected."
        return 1
    fi

    # Prompt for patch name
    echo -n "Enter patch name: "
    read patch_name

    if [[ -z "$patch_name" ]]; then
        echo "Patch name cannot be empty."
        return 1
    fi

    # Sanitize patch name (replace spaces with underscores)
    patch_name="${patch_name// /_}"
    local patch_file="${GPATCH_DIR}/${patch_name}.patch"

    if [[ -f "$patch_file" ]]; then
        echo -n "Patch '$patch_name' already exists. Overwrite? [y/N] "
        read confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "Aborted."
            return 1
        fi
    fi

    # Create the patch from selected files
    echo "$selected_files" | xargs git diff HEAD -- > "$patch_file"

    echo "Patch saved to: $patch_file"
    echo "Files included:"
    echo "$selected_files" | sed 's/^/  /'
}

function gpatch-list() {
    mkdir -p "$GPATCH_DIR"

    local patches
    patches=$(ls -1 "$GPATCH_DIR"/*.patch 2>/dev/null)

    if [[ -z "$patches" ]]; then
        echo "No patches found in $GPATCH_DIR"
        return 0
    fi

    echo "Available patches:"
    for patch in "$GPATCH_DIR"/*.patch; do
        local name=$(basename "$patch" .patch)
        local lines=$(( $(wc -l < "$patch") ))  # BSD wc pads the count with spaces
        local files=$(grep -c "^diff --git" "$patch")
        echo "  $name ($files files, $lines lines)"
    done
}

function gpatch-apply() {
    mkdir -p "$GPATCH_DIR"

    local patches
    patches=$(ls -1 "$GPATCH_DIR"/*.patch 2>/dev/null | xargs -I {} basename {} .patch)

    if [[ -z "$patches" ]]; then
        echo "No patches found in $GPATCH_DIR"
        return 1
    fi

    # Use fzf to select a patch with preview
    local selected
    selected=$(echo "$patches" | fzf --preview "cat ${GPATCH_DIR}/{}.patch" --preview-window=right:60%:wrap --header="Select patch to apply")

    if [[ -z "$selected" ]]; then
        echo "No patch selected."
        return 1
    fi

    local patch_file="${GPATCH_DIR}/${selected}.patch"

    # Check if patch can be applied
    if git apply --check "$patch_file" 2>/dev/null; then
        git apply "$patch_file"
        echo "Patch '$selected' applied successfully."
    else
        echo "Patch cannot be applied cleanly. Try with --3way? [y/N] "
        read confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            git apply --3way "$patch_file"
        else
            echo "Aborted."
            return 1
        fi
    fi
}

function gpatch-delete() {
    mkdir -p "$GPATCH_DIR"

    local patches
    patches=$(ls -1 "$GPATCH_DIR"/*.patch 2>/dev/null | xargs -I {} basename {} .patch)

    if [[ -z "$patches" ]]; then
        echo "No patches found in $GPATCH_DIR"
        return 1
    fi

    local selected
    selected=$(echo "$patches" | fzf --preview "cat ${GPATCH_DIR}/{}.patch" --preview-window=right:60%:wrap --header="Select patch to DELETE")

    if [[ -z "$selected" ]]; then
        echo "No patch selected."
        return 1
    fi

    echo -n "Delete patch '$selected'? [y/N] "
    read confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        rm "${GPATCH_DIR}/${selected}.patch"
        echo "Patch '$selected' deleted."
    else
        echo "Aborted."
    fi
}

function gpatch-show() {
    mkdir -p "$GPATCH_DIR"

    local patches
    patches=$(ls -1 "$GPATCH_DIR"/*.patch 2>/dev/null | xargs -I {} basename {} .patch)

    if [[ -z "$patches" ]]; then
        echo "No patches found in $GPATCH_DIR"
        return 1
    fi

    local selected
    selected=$(echo "$patches" | fzf --preview "cat ${GPATCH_DIR}/{}.patch" --preview-window=right:60%:wrap --header="Select patch to view")

    if [[ -z "$selected" ]]; then
        return 0
    fi

    cat "${GPATCH_DIR}/${selected}.patch"
}

function gdiff() {
  GIT_EXTERNAL_DIFF=difft git diff
  GIT_EXTERNAL_DIFF=
}

function gclone() {
    # Check if a repository URL is provided
    if [ -z "$1" ]; then
        echo "Usage: gclone <repository-url> [directory]"
        return 1
    fi

    # Extract parameters
    local repo_url="$1"
    local repo_dir="$2"

    # List valid SSH identity files
    local ssh_dir=$HOME/.ssh
    local -a valid_identity_files=()
    # 0 also covers the "no identity files at all" path below, where the
    # selection loop never runs
    local identity_choice=0

    for file in "$ssh_dir"/*; do
        # Check if the file has a corresponding .pub file
        if [[ -f "$file" && -f "$file.pub" ]]; then
            valid_identity_files+=("$file")
        fi
    done

    if [ ${#valid_identity_files[@]} -eq 0 ]; then
        echo "No SSH identity files found."
    else
        echo "Select an SSH identity file to use for cloning the repository:"
        echo "----------------------------------------"

        # Add an option to use the default SSH configuration
        echo "0) Use default SSH configuration [Default]"

        # Display identity files with numbers
        local i=1
        for file in "${valid_identity_files[@]}"; do
            echo "$i) $file"
            ((i++))
        done

        # Ask the user to select an SSH identity file by number
        while true; do
            echo -n "Enter choice (default is 0): "
            read identity_choice
            if [[ -z "$identity_choice" ]]; then
                identity_choice=0
                break
            elif [[ "$identity_choice" =~ ^[0-9]+$ ]] && [ "$identity_choice" -ge 0 ] && [ "$identity_choice" -le ${#valid_identity_files[@]} ]; then
                break
            else
                echo "Invalid selection. Please enter a valid number."
            fi
        done
    fi

    # Set up the GIT_SSH_COMMAND if an identity file was chosen
    local git_ssh_command=""
    if [ "$identity_choice" -ne 0 ]; then
        local selected_identity
        selected_identity=$(__sh_nth "$identity_choice" "${valid_identity_files[@]}")
        git_ssh_command="GIT_SSH_COMMAND='ssh -i $selected_identity'"
        echo "Using SSH identity file: $selected_identity."
    else
        git_ssh_command=""
        echo "Using default SSH configuration."
    fi

    # Execute the clone command with the selected SSH identity
    if [ "$identity_choice" -ne 0 ]; then
        echo "Cloning repository with custom SSH identity. Command is: eval $git_ssh_command git clone $repo_url $repo_dir"
        eval "$git_ssh_command git clone $repo_url $repo_dir"
    else
        echo "Cloning repository without custom SSH identity. Command is: git clone $repo_url $repo_dir"
        eval "git clone $repo_url $repo_dir"
    fi

    if [ $? -ne 0 ]; then
        echo "Failed to clone the repository."
        return 1
    fi

    # Change to the cloned repository directory
    if [ -z "$repo_dir" ]; then
        repo_dir=$(basename "$repo_url" .git)
    fi

    cd "$repo_dir" || return

    # Signing is left alone: ~/.gitconfig turns it on per machine and the identity
    # included for the remote picks the key
    echo "Repository cloned successfully."
}

# To use the function, add this line to your ~/.zshrc file and restart your shell

# Lists only what is still unstaged; a file with both staged and unstaged changes
# shows up once and its preview is the remaining (index -> worktree) delta.
function gadd () {
    local root selected_files
    root=$(git rev-parse --show-toplevel) || return 1

    selected_files=$(
        cd "$root" || exit 1
        # -uall: list untracked files individually instead of collapsing to "dir/"
        # -z:    never quotes paths (no "with space.txt"), NUL-delimited records
        # tr:    BSD awk (macOS) cannot split records on NUL, so make them lines
        git status --porcelain -z -uall | tr '\0' '\n' | awk '
        {
            x = substr($0, 1, 1);   # index status    (staged)
            y = substr($0, 2, 1);   # worktree status (unstaged)
            path = substr($0, 4);

            # renames emit a second record holding the original path; drop it
            if (x == "R" || x == "C") getline discard;

            if (y == " ") next;     # fully staged, nothing left to add

            unmerged = (x == "U" || y == "U" || (x == "A" && y == "A") || (x == "D" && y == "D"));
            mark = (!unmerged && x != " " && x != "?") ? "*" : "";   # * = also partly staged

            if (unmerged) {
                status="[U]";
                color="\033[35m"; # Magenta for merge conflicts
            }
            else if (y == "?") {
                status="[A]";
                color="\033[32m"; # Green for new files
            }
            else if (y == "D") {
                status="[D]";
                color="\033[31m"; # Red for deleted files
            }
            else {
                status="[M]";
                color="\033[33m"; # Yellow for modified files
            }
            print color status mark " " path "\033[0m";
        }' | sort -u | fzf -m --ansi --color light --delimiter ' ' --nth 2.. --preview '
        file=$(printf "%s" {} | cut -d" " -f2-)
        if git ls-files --error-unmatch -- "$file" > /dev/null 2>&1; then
            git diff -- "$file" | delta --paging=never --width=${FZF_PREVIEW_COLUMNS:-80}
        else
            printf "\033[1;32m-- new file --\033[0m\n"
            bat --color=always --style=plain -- "$file" 2>/dev/null || cat -- "$file"
        fi' --bind "ctrl-/:change-preview-window(down|hidden|90%),tab:toggle,ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all" --header "Select files to stage (* = partly staged already; preview shows the unstaged delta)")

    if [ -n "$selected_files" ]; then
        echo "$selected_files" | cut -d' ' -f2- | tr '\n' '\0' |
            ( cd "$root" && xargs -0 -r git add -- )
        echo "Added files:"
        echo "$selected_files" | cut -d' ' -f2-
    else
        echo "No files selected. Exiting without git add."
    fi
}

# Throws work away, so it asks first. Tracked files are restored from the index,
# untracked files are DELETED -- and the two run as separate commands, because git
# aborts a whole batch when one pathspec is wrong (checkout cannot touch an
# untracked path, which used to make this function silently revert nothing).
function grevert() {
    local root selected tracked untracked
    root=$(git rev-parse --show-toplevel) || return 1

    selected=$(
        cd "$root" || exit 1
        git --no-optional-locks status --porcelain -z -uall --ignore-submodules=dirty | tr '\0' '\n' | awk '
        {
            x = substr($0, 1, 1);   # index status    (staged)
            y = substr($0, 2, 1);   # worktree status (unstaged)
            path = substr($0, 4);

            if (x == "R" || x == "C") getline discard;

            if (y == " ") next;     # nothing in the worktree to throw away
            # conflicts get resolved or "git merge --abort"ed, not reverted
            if (x == "U" || y == "U" || (x == "A" && y == "A") || (x == "D" && y == "D")) next;

            mark = (x != " " && x != "?") ? "*" : "";   # * = reverts to the staged version, not HEAD

            if (y == "?") {
                status="[A]";
                color="\033[32m"; # Green for new files (these get DELETED)
            }
            else if (y == "D") {
                status="[D]";
                color="\033[31m"; # Red for deleted files (these come back)
            }
            else {
                status="[M]";
                color="\033[33m"; # Yellow for modified files
            }
            print color status mark " " path "\033[0m";
        }' | sort -u | fzf -m --ansi --color light --delimiter ' ' --nth 2.. --preview '
        file=$(printf "%s" {} | cut -d" " -f2-)
        if git ls-files --error-unmatch -- "$file" > /dev/null 2>&1; then
            printf "\033[1;33m-- these changes will be DISCARDED --\033[0m\n"
            git diff -- "$file" | delta --paging=never --width=${FZF_PREVIEW_COLUMNS:-80}
        else
            printf "\033[1;31m-- this untracked file will be DELETED --\033[0m\n"
            bat --color=always --style=plain -- "$file" 2>/dev/null || cat -- "$file"
        fi' --bind "ctrl-/:change-preview-window(down|hidden|90%),tab:toggle,ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all" --header "Select files to revert ([A] files are DELETED; * = reverts to the staged version)")

    if [ -z "$selected" ]; then
        echo "No files reverted."
        return 0
    fi

    tracked=$(echo "$selected" | grep -v '^\[A\]' | cut -d' ' -f2-)
    untracked=$(echo "$selected" | grep '^\[A\]' | cut -d' ' -f2-)

    echo "$selected" | cut -d' ' -f2- | sed 's/^/  /'
    __sh_confirm "Discard the above (tracked reverted, untracked DELETED)? [y/N] " || { echo "Aborted."; return 1; }

    if [ -n "$tracked" ]; then
        echo "$tracked" | tr '\n' '\0' | ( cd "$root" && xargs -0 -r git restore -- )
        echo "Reverted:"
        echo "$tracked"
    fi
    if [ -n "$untracked" ]; then
        echo "$untracked" | tr '\n' '\0' | ( cd "$root" && xargs -0 -r git clean -qf -- )
        echo "Deleted:"
        echo "$untracked"
    fi
}

# Lists only what is actually in the index, and previews "git diff --cached" --
# the staged diff, which is exactly what leaves the index. (A staged rename holds
# two index entries, so it shows up as two rows: [R] new path, [D] old path.)
function gunstage() {
    local root selected
    root=$(git rev-parse --show-toplevel) || return 1

    selected=$(
        cd "$root" || exit 1
        git --no-optional-locks status --porcelain -z -uall --ignore-submodules=dirty | tr '\0' '\n' | awk '
        {
            x = substr($0, 1, 1);   # index status    (staged)
            y = substr($0, 2, 1);   # worktree status (unstaged)
            path = substr($0, 4);

            orig = "";
            if (x == "R") getline orig;          # staged rename: source path is a staged deletion
            else if (x == "C") getline discard;

            if (x == " " || x == "?") next;      # nothing staged
            if (x == "U" || y == "U" || (x == "A" && y == "A") || (x == "D" && y == "D")) next;

            mark = (y != " ") ? "*" : "";        # * = unstaged edits stay in the worktree

            if (x == "A") {
                status="[A]";
                color="\033[32m"; # Green for added files
            }
            else if (x == "D") {
                status="[D]";
                color="\033[31m"; # Red for deleted files
            }
            else if (x == "R" || x == "C") {
                status="[R]";
                color="\033[36m"; # Cyan for renames
            }
            else {
                status="[M]";
                color="\033[33m"; # Yellow for modified files
            }
            print color status mark " " path "\033[0m";
            if (orig != "") print "\033[31m[D] " orig "\033[0m";
        }' | sort -u | fzf -m --ansi --color light --delimiter ' ' --nth 2.. --preview '
        file=$(printf "%s" {} | cut -d" " -f2-)
        printf "\033[1;32m-- staged, will be removed from the index --\033[0m\n"
        git diff --cached -- "$file" | delta --paging=never --width=${FZF_PREVIEW_COLUMNS:-80}
        ' --bind "ctrl-/:change-preview-window(down|hidden|90%),tab:toggle,ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all" --header "Select files to unstage (* = unstaged edits stay in the worktree)")

    if [ -n "$selected" ]; then
        echo "$selected" | cut -d' ' -f2- | tr '\n' '\0' |
            ( cd "$root" && xargs -0 -r git restore --staged -- )
        echo "Unstaged files:"
        echo "$selected" | cut -d' ' -f2-
    else
        echo "No files unstaged."
    fi
}

# Live index UI: stage / unstage / patch / discard without leaving fzf.
#   Two columns: left = index (green), right = worktree (yellow), dim dot = clean.
#   So .M is unstaged, M. is staged, MM is both, and .A is a new untracked file.
#   enter stages the selection and exits, so it is a superset of gadd.
function gs () {
    local root awk_prog list selected
    root=$(git rev-parse --show-toplevel) || return 1

    # Kept OUT of the --bind strings on purpose: fzf finds the end of an action(...)
    # by matching parens, and this program is full of them. Passed via the
    # environment instead, which fzf's child shells inherit.
    awk_prog='
    {
        x = substr($0, 1, 1); y = substr($0, 2, 1); path = substr($0, 4)
        if (x == "R" || x == "C") getline discard
        # untracked: git says "??", but nothing is staged -- it is a new file in the
        # worktree only, so stage it and the A migrates to the index column.
        if (x == "?") { x = " "; y = "A" }
        xcell = (x == " ") ? "\033[90m\302\267" : "\033[32m" x   # index column, green
        ycell = (y == " ") ? "\033[90m\302\267" : "\033[33m" y   # worktree column, yellow
        printf "%s%s\033[0m %s\n", xcell, ycell, path
    }'
    list='git --no-optional-locks status --porcelain -z -uall --ignore-submodules=dirty | tr "\0" "\n" | awk "$_GS_AWK" | sort -u'

    selected=$(
        cd "$root" || exit 1
        export _GS_AWK=$awk_prog
        eval "$list" | fzf -m --ansi --color light \
            --delimiter ' ' --nth 2.. \
            --header 'enter stage+exit | C-s stage | C-u unstage | C-p patch | C-x discard | C-/ preview' \
            --preview '
            f={2..}
            if git ls-files --error-unmatch -- "$f" > /dev/null 2>&1; then
                s=$(git diff --cached -- "$f"); u=$(git diff -- "$f")
                [ -n "$s" ] && { printf "\033[1;32m-- staged --\033[0m\n"; printf "%s\n" "$s" | delta --paging=never --width=${FZF_PREVIEW_COLUMNS:-80}; }
                [ -n "$u" ] && { printf "\033[1;33m-- unstaged --\033[0m\n"; printf "%s\n" "$u" | delta --paging=never --width=${FZF_PREVIEW_COLUMNS:-80}; }
            else
                printf "\033[1;32m-- new file --\033[0m\n"; bat --color=always --style=plain -- "$f" 2>/dev/null || cat -- "$f"
            fi' \
            --bind "ctrl-s:execute-silent(git add -- {+2..})+reload($list)" \
            --bind "ctrl-u:execute-silent(git restore --staged -- {+2..})+reload($list)" \
            --bind "ctrl-p:execute(git add -p -- {2..})+reload($list)" \
            --bind "ctrl-x:execute(printf 'discard unstaged changes to %s? [y/N] ' {2..}; read a; [ \"\$a\" = y ] && git restore -- {2..})+reload($list)" \
            --bind 'ctrl-/:change-preview-window(down|hidden|90%),tab:toggle,ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all'
    )

    if [ -n "$selected" ]; then
        echo "$selected" | cut -d' ' -f2- | tr '\n' '\0' |
            ( cd "$root" && xargs -0 -r git add -- )
        echo "Staged:"
        echo "$selected" | cut -d' ' -f2-
    fi
}

function gmerge() {
  git fetch origin
  # first fetch the branches and pipe to fzf for selection
  source=$(git branch -r | fzf --height 40% --reverse --inline-info --preview "git log --oneline {1} | head -n 1" | awk '{print $1}')
  # check if the user selected a branch
  if [ -z "$source" ]; then
    echo "No branch selected. Exiting."
    return
  fi
  git stash --include-untracked
  git merge $source
  git stash pop
  gstat
}

function gpsh() {
  branch=`git rev-parse --abbrev-ref HEAD`
  remote=`git for-each-ref --format='%(upstream:short)' "$(git symbolic-ref -q HEAD)"`

  if [ -z "$remote" ]
  then
    git push --set-upstream origin "$branch"
  else
    git push
  fi
}

function gfork() {
  # Check if a branch name is provided as an argument
  if [ -z "$1" ]; then
    # Prompt the user for a branch name if it's not provided
    echo -n "Enter branch name: "
    read bname
  else
    # Use the provided branch name
    bname=$1
  fi

  echo "Forking current branch to new branch: $bname"

  # Use fzf to select a commit and fork from it
  git fork $bname "$(git log --pretty=oneline | fzf | cut -f 1 -d ' ')"

  # Switch to the new branch
  gswitch $bname
}

function gcob() {
  git checkout $(git branch | fzf)
}

function gcorb() {
  git checkout --track $(git branch -r | fzf)
}

function gremotes() {
  echo "[`date`][SWARANGA]: git remote -v";
  git remote -v;
}

function greset() {
  local commitHash=`git log --pretty=format:"%h - %s" | fzf | awk '{print $1}'`
  git reset $commitHash $1
}

function __fuzzySelectGitBranch () {
          local multi_select=false

          # Check if multi-select flag is passed
          if [ "$1" = "-m" ] || [ "$1" = "--multi" ]; then
                  multi_select=true
          fi

          local max_branch_length
          max_branch_length=$(git for-each-ref --format="%(refname:short)" refs/heads/ | awk '{ if (length > max) max = length } END { print max }')
          local padding=2
          local branch_column_width=$((max_branch_length + padding))
          local selected

          local branches
          branches=$(git for-each-ref --sort=committerdate --format="%(refname:short) %(committerdate:iso) %(subject)" refs/heads/ |
              awk -v branch_width="$branch_column_width" '{branch=$1; date=$2; message=substr($0, index($0,$3)); printf "%-" branch_width "s %-25s %s\n",
   branch, date, message}')

          if [ "$multi_select" = true ]; then
                  selected=$(echo "$branches" | fzf -m --reverse --prompt="Select branch(es): " --tac \
                          --preview='git show --name-only --oneline $(git rev-parse --verify $(echo {} | awk "{print \$1}"))' \
                          --bind "tab:toggle,ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all" \
                          --header "Select branches (tab:toggle, ctrl-a:select-all)")
          else
                  selected=$(echo "$branches" | fzf --reverse --prompt="Select a branch: " --tac \
                          --preview='git show --name-only --oneline $(git rev-parse --verify $(echo {} | awk "{print \$1}"))')
          fi

          if [ -n "$selected" ]; then
                  echo "$selected" | awk '{print $1}'
          fi
}

function gdelb () {
          if [ -z "$1" ]
          then
                  local branch_names
                  branch_names=$(__fuzzySelectGitBranch -m)
                  if [ -n "$branch_names" ]
                  then
                          echo "$branch_names" | while read -r branch_name; do
                                  git branch -D "$branch_name"
                          done
                          printf '\nDeleted branches:\n'
                          echo "$branch_names"
                  else
                          echo "No branch selected"
                  fi
          else
                  local branch_name=$1
                  git branch -D "$branch_name"
          fi
  }

function gswitch () {
    if [ -z "$1" ]
    then
        local branch_name
        branch_name=$(__fuzzySelectGitBranch)
        if [ -n "$branch_name" ]
        then
            git checkout "$branch_name"
        fi
    else
        local branch_name=$1 
        git checkout "$branch_name"
    fi
}

function gcreateb() {
  echo "[`date`][SWARANGA]: git checkout -b $1";
  git checkout -b $1;
}

function gpl() {
  echo "[`date`][SWARANGA] : git pull --rebase";
  git pull --rebase;
}

function gstash () {
      # First, prompt for stash message
      local stash_msg
      echo -n "Enter stash message (optional): "
      read stash_msg

      # Then, select files to stash using fzf
      selected_files=$(
          (
              git status --porcelain | grep -v '^?? .*/'
              git ls-files --others --exclude-standard | awk '{print "?? "$0}'
          ) | awk '
          {
              status=$1;
              file=$2;
              if (status == "??") {
                  status="[A]";
                  color="\033[32m"; # Green for new files
              }
              else if (status ~ /^A/) {
                  status="[A]";
                  color="\033[32m"; # Green for added files
              }
              else if (status ~ /^M/) {
                  status="[M]";
                  color="\033[33m"; # Yellow for modified files
              }
              else if (status ~ /^D/) {
                  status="[D]";
                  color="\033[31m"; # Red for deleted files
              }
              print color status " " file "\033[0m";
          }' | sort -u | fzf -m --ansi --color light --preview '
          file=$(echo {} | awk "{print \$2}")
          if git ls-files --error-unmatch "$file" > /dev/null 2>&1; then
              if [ -f "$file" ]; then
                  git diff --color=always HEAD "$file"
              else
                  git show --color=always HEAD:"$file" | sed "s/^/\\x1b[31m/" | sed "s/$/\\x1b[0m/"
              fi
          else
              git diff --color=always --no-index /dev/null "$file"
          fi' --bind "ctrl-/:change-preview-window(down|hidden|90%),tab:toggle,ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all" --header "Select
   files to stash"
      )

      # Process selected files
      if [ -n "$selected_files" ]; then
          local files_to_stash=$(echo "$selected_files" | awk '{print $2}')

          if [ -z "$stash_msg" ]; then
              echo "$files_to_stash" | xargs git stash push --include-untracked
          else
              echo "$files_to_stash" | xargs git stash push --include-untracked -m "$stash_msg"
          fi

          echo "Stashed files with message: '$stash_msg'"
          echo "Files stashed:"
          echo "$files_to_stash"
      else
          echo "No files selected. Exiting without stashing."
      fi
}

function gunstash() {
  local selected_stash
  selected_stash=$(git stash list | fzf --height 40% --reverse --inline-info --preview 'git stash show -p $(echo {1} | sed "s/.*{\([0-9]*\)}.*/\1/")' | awk '{print $1}' | awk -F'[{}]' '{print $2}')
  if [ -n "$selected_stash" ]; then
    git stash pop "$selected_stash"
    echo "Unstashed changes from: $selected_stash"
  else
    echo "No stash selected. Exiting."
  fi
}
