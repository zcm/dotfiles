complete -c brazil-build -f -l 'help' --description 'Display usage information'
complete -c brazil-build -f -n 'test -f build.xml' -a '(__fish_complete_brazil_targets)' --description "Brazil target"
