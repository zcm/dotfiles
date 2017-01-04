function _ga --description "Run a git command in each git repository under the current directory."
  set -l continue_ga 0
  if hostname | grep -q amazon\.com
    if not check_ticket
      set continue_ga 1
      echo "Failed to update credentials."
    end
  end
  if [ $continue_ga = 0 ]
    for each in (ls -d */)
      if not fish -c "cd $each > /dev/null; if_in_git_tree_do git $argv"
        return
      end
    end
  end
end
