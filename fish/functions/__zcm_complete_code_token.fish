function __zcm_complete_code_token --description "Generates autocompletions for the specified code token."
  set -l pattern "^"$argv[1]".*"
  set -l global_output (global -x $pattern | sed -r -e 's/\s.*$//g')
  echo $global_output
end
