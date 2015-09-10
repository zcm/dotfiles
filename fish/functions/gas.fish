function gas --description "Run 'git status' in each git repository under the current directory."
  for each in (ls -d */)
    pushd $each
    if_in_git_tree_do git status $argv
    popd
  end
end
