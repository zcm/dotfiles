function vimack --description "Edit the file(s) that contain the specified pattern in Vim."
  eval "command vim" (ack -l $argv)
end
