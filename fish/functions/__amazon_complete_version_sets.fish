function __amazon_complete_version_sets
  __amazon_zsh_cache_wrapper list-version-sets.pl | grep '^'(commandline -ct)
end
