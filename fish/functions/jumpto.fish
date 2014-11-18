function jumpto --description "Jump to the folder that contains the file for the specified class."
  cd (global -a $argv | sed 's,/*[^/]\+/*$,,')
end
