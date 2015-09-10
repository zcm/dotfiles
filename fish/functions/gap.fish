function gap --description "Run 'git pull' in each git repository under the current directory."
  for each in (ls -d */)
    pushd $each
    if_in_git_tree_do git pull $argv
    popd
  end
end
