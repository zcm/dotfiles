function gap --description "Run 'git pull' in each git repository under the current directory."
  _ga pull $argv
  if command -v global
    global -u ^ /dev/null
  end
end
