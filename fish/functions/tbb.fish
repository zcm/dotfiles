function tbb
  tmux split-window -p 80 "brazil-build $argv; sleep 36000"
  tmux swap-pane -U -d
end
