#!/bin/bash

# depends on: fd, fzf

ROOT_DIR="$HOME"

# match all .git dirs without a . in parent path e.g. .local/../../.git is ignored
dirs=$(fd '\.git$' "$ROOT_DIR" -u --prune -t d -x dirname {} | grep -v '/\..*')
echo "$dirs"

api_output=$(sed "s%^%$ROOT_DIR/%g" repos.json)
echo "$api_output"

selected_repo=$(printf "%s\n%s\n" "$dirs" "$api_output" \
  | sort \
  | fzf --height 40% --border --ansi --prompt "Select a repository: ")

if [ ! -d "$selected_repo" ]; then
  echo "Repo not found... beginning clone."
  echo "$selected_repo"
  # TODO: insert git clone here
  # git clone "${1//github.com/$GIT_TOKEN@github.com}"
fi

WINDOW_NAME="$(basename "$selected_repo")"

SESSION_NAME="dev"

if ! tmux has-session -t "$SESSION_NAME"; then
  tmux new-session -d -s "$SESSION_NAME"
fi

if tmux list-windows -t "$SESSION_NAME" | grep -q "$WINDOW_NAME"; then
  echo "$WINDOW_NAME already exists in session $SESSION_NAME."
else
  tmux new-window -t "$SESSION_NAME" -n "$WINDOW_NAME"
  echo "New window $WINDOW_NAME created in session $SESSION_NAME."
fi

if [[ -z "$TMUX" ]]; then
  tmux attach-session -t "$SESSION_NAME"
else
  CURRENT_SESSION=$(tmux display-message -p '#S')
  if [[ "$CURRENT_SESSION" != "$SESSION_NAME" ]]; then
    tmux switch-client -t "$SESSION_NAME"
  else
    tmux select-window -t "$WINDOW_NAME"
  fi
fi

if ! tmux has-session -t "$SESSION_NAME"; then
  tmux new-session -d -s "$SESSION_NAME"
fi

if tmux list-windows -t "$SESSION_NAME" | grep -q "$WINDOW_NAME"; then
  : "$WINDOW_NAME" already exists
else
  tmux new-window -t "$SESSION_NAME" -n "$WINDOW_NAME"
  tmux new-window -t "$SESSION_NAME" -n "rouygh"
fi

if [[ -z "$TMUX" ]]; then
    : Not attached to tmux
else
    CURRENT_SESSION=$(tmux display-message -p '#S')
    if [[ "$CURRENT_SESSION" != "$SESSION_NAME" ]]; then
        : Already attached to a different session
        tmux switch-client -t "$SESSION_NAME"
    fi
fi

tmux select-window -t "$SESSION_NAME:$WINDOW_NAME"

if [[ "$(tmux list-panes -t "$SESSION_NAME:$WINDOW_NAME" -F '#{pane_current_command}')" =~ bash|tmux ]]; then
  tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME" "cd $selected_repo && nvim ." Enter
fi

