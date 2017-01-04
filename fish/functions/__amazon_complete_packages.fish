function __amazon_complete_packages
  __amazon_zsh_cache_wrapper list-brazil-packages.pl | grep '^'(commandline -ct)
end
