function bwl --description "Run 'brazil ws list' in way compatible with GNU Global."
  set -l exclude_param "GTAGS,GPATH,GRTAGS"
  set -l found_exclude "false"
  set -l found_pull "false"
  for arg in $argv
    if [ $found_exclude = "true" ]
      set exclude_param "$found_exclude,$arg"
      set found_exclude "false"
      break
    end
    if begin [ $arg = "--exclude" ]; or [ $arg = "exclude" ]; end
      set found_exclude "true"
      break
    end
    if [ $found_pull = "false" ]
      set found_pull "true"
      break
    end
  end
  if [ $found_pull = "true" ]
    #brazil ws list --exclude $exclude_param --pull
    echo brazil ws list --exclude $exclude_param --pull
  else
    #brazil ws list --exclude $exclude_param
    echo brazil ws list --exclude $exclude_param
  end
end
