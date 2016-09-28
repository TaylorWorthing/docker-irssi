#!/bin/sh

# Create or connect to a specific tmux session, with a command.
# IF interactive shell AND remote connection AND not already in tmux.
if [ -n "$PS1" ] && [ -n "$SSH_CONNECTION" ] && [ -z "$TMUX" ]; then
  SESSION_NAME="remote"
  SESSION_COMMAND="irssi"

  sleep 1

  ( (tmux attach-session -t "$SESSION_NAME" 2>/dev/null) ||
    (tmux new-session -s "$SESSION_NAME" "$SESSION_COMMAND") )

  if [ "$?" -eq 0 ]; then
    exit 0 # Exit when session is detached or closed.
  else
    echo "tmux failed to start"
  fi
fi
