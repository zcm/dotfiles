function vimclass --description "Edit the file containing the specified class in Vim."
  set -l search_target $argv[1]
  if [ "$search_target" = "" ]
    echo "vimclass: error: must specify target class" >&2
    return
  end
  set -l found_file (global -a $search_target | xargs)
  if [ "$found_file" = "" ]
    set found_file (ack -l "\bclass $search_target\b" --ignore-file=ext:html,xml)
  end
  if [ "$found_file" = "" ]
    echo "vimclass: error: cannot locate class '$search_target'" >&2
  else
    eval "command vim" $found_file
  end
end
