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
  set -l color_base (set_color --bold white)
  set -l color_back (set_color --bold black)
  set -l color_user (set_color --bold green)
  set -l color_host (set_color --bold purple)
  if [ "$TERM" != "linux" ]
    set color_user (set_color --bold F80)
    set color_host (set_color --bold 92F)
  end
  set -l color_cwd (set_color --bold $fish_color_cwd)
  printf "%s[%s%s%s@%s%s %s%s%s]%s%s " \
    $color_base \
      $color_user $USER \
      $color_back \
      $color_host (hostname -s) \
      $color_cwd $pwd \
    $color_base \
    $prompt_symbol (set_color normal)
end
