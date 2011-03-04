let VIM_env_save=$VIM
let HOME_env_save=$HOME
let s:runtimepath_save=&runtimepath
let &runtimepath=&runtimepath.",F:/Users/dremelofdeath,F:/Users/dremelofdeath/.vim"

if(has("gui_win32"))
  if($COMPUTERNAME == "BLISS-PC")
    " A very, very special case...
    source F:\Users\dremelofdeath\.vimrc
  else
    source $HOME\.vimrc
  endif
else
  " WTF are you doing, this for Windows and you shouldn't get here.
  " Oh well, you are retarded, but source the vimrc on a best-effort basis...
  source $HOME\.vimrc
endif

let &runtimepath=s:runtimepath_save
unlet s:runtimepath_save
let $HOME=HOME_env_save
let $VIM=VIM_env_save
let $MACVIMRC='F:/Users/dremelofdeath/.vimrc'
