#!/usr/bin/env bash

#This was inspired by
# https://gist.github.com/mikeboiko/b6e50210b4fb351b036f1103ea3c18a9
# and
# https://github.com/rjmccabe3701/linux_config/blob/master/scripts/update_display.sh

# The problem:
# When you `ssh -X` into a machine and attach to an existing tmux session, the session
# contains the old $WAYLAND_DISPLAY env variable. In order the x-server/client to work properly,
# you have to update $WAYLAND_DISPLAY after connection. For example, the old $WAYLAND_DISPLAY=:0 and
# you need to change to $WAYLAND_DISPLAY=localhost:10.0 for my ssh session to
# perform x-forwarding properly.

# The solution:
# When attaching to tmux session, update $WAYLAND_DISPLAY for each tmux pane in that session.
# This is performed by using tmux send-keys to the shell. It will update the WAYLAND_DISPLAY
# for panes running:
#   * zsh
#   * bash
#   * vim/nvim
#   * python
# If a pane is running something else (e.g. an ssh session into another machine) it
# is ignored.  Even if the pane is running one of the above processes, if you exit that
# process (say its running nvim and you exit to the zsh shell), the parent process
# will have the old WAYLAND_DISPLAY variable.  In these cases manually run this script later.

NEW_WAYLAND_DISPLAY=$(tmux show-env | sed -n 's/^WAYLAND_DISPLAY=//p')
tmux list-panes -s -F "#{session_name}:#{window_index}.#{pane_index} #{pane_current_command}" | \
while read pane_process
do
   IFS=' ' read -ra pane_process <<< "$pane_process"
   if [[ "${pane_process[1]}" == "zsh" || "${pane_process[1]}" == "bash" ]]; then
      tmux send-keys -t ${pane_process[0]} "export WAYLAND_DISPLAY=$NEW_WAYLAND_DISPLAY" Enter
   elif [[ "${pane_process[1]}" == *"python"* ]]; then
      tmux send-keys -t ${pane_process[0]} "import os; os.environ['WAYLAND_DISPLAY']=\"$NEW_WAYLAND_DISPLAY\"" Enter
   elif [[ "${pane_process[1]}" == *"vim"* ]]; then
      tmux send-keys -t ${pane_process[0]} Escape
      tmux send-keys -t ${pane_process[0]} ":let \$WAYLAND_DISPLAY = \"$NEW_WAYLAND_DISPLAY\"" Enter
   fi
done

