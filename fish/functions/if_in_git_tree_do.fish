function if_in_git_tree_do --description "Run the given command and arguments only if the current working directory is inside a git tree."
  set -l short_form "false"
  for arg in $argv
    # Try to find if we want to use the short form or not.
    if [ $arg = "--short" ]
      set short_form "true"
      break
    end
    if [ $arg = "-s" ]
      set short_form "true"
      break
    end
    echo $arg | sed '/-.*s.*/q; /-.*s.*/!{q1}' > /dev/null
    if [ $status = 0 ]
      set short_form "true"
      break
    end
  end
  if [ "git "(git rev-parse --is-inside-work-tree ^&1) = "git true" ]
    set_color green
    echo -n (basename (pwd))
    set_color normal
    if [ $short_form = "true" ]
      echo ":"
    else
      echo -n " - "
    end
    eval $argv
    echo
  end
end
