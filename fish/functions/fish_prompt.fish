function fish_prompt --description 'Write out the prompt'
  set -l home_escaped (echo -n $HOME | sed 's/\//\\\\\//g')
  #set -l pwd (echo -n $PWD | sed "s/^$home_escaped/~/" | sed 's/ /%20/g')
  set -l pwd "~"
  if [ "$PWD" != "$HOME" ]
    set pwd (echo -n (basename (pwd)))
  end
  set -l prompt_symbol ''
  switch $USER
    case root; set prompt_symbol '#'
    case '*';  set prompt_symbol '$'
  end
  printf "%s[%s%s%s@%s%s %s%s%s]%s%s " (set_color --bold white) (set_color --bold F80) $USER (set_color --bold black) (set_color --bold 92F) (hostname -s) (set_color --bold $fish_color_cwd) $pwd (set_color --bold white) $prompt_symbol (set_color normal)
end
