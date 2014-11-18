function __zcm_complete_code_token --description "Generates autocompletions for the specified code token."
  global -x "^"$argv[1]".*" | sed -r -e 's/\s.*$//g'
end
