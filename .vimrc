set nocompatible
set showcmd

if has("persistent_undo")
  set undofile
endif

if has("gui_macvim")
  sil! set gfn=ProggySquare:h11
endif

let g:dock_hidden = 0

" on Mac OS X, gets the computer name (not the host name)
function MacGetComputerName()
  let computernamestring = system("scutil --get ComputerName")
  return strpart(computernamestring, 0, strlen(computernamestring)-1)
endfunction

" on Mac OS X, toggle hiding the dock
function MacToggleDockHiding()
  if g:dock_hidden == 0
    let g:dock_hidden = 1
    " this is to make sure that the dock is unhidden on exit
    aug zcm_dock_hiding
    au zcm_dock_hiding VimLeave * call MacToggleDockHiding()
    aug END
  else
    let g:dock_hidden = 0
    " this should make sure that the dock isn't touched
    " if it's been manually unhidden
    aug zcm_dock_hiding
    au! zcm_dock_hiding
    aug END
  endif
  call system("osascript -e 'tell app \"System Events\" to keystroke \"d\" using {command down, option down}'")
endfunction

" these two functions allow the user to toggle between
" standard comments and Doxygen comments
function EnableDoxygenComments()
  let b:zcm_doxified = 1
  set syn+=.doxygen
endfunction
function DisableDoxygenComments()
  let b:zcm_doxified = 0
  set syn-=.doxygen
endfunctio

function ToggleDoxygenComments()
  if b:zcm_doxified == 0
    call EnableDoxygenComments()
    " this should be defined in the zcm_folding au group
    "if b:open_all_folds_bfbn == 1
    " silent! %foldo!
    "endif
  else
    call DisableDoxygenComments()
  endif
endfunction

" function for fullscreen maximize, at least on a 1280x800 Macintosh desktop
" NOTE: you must use a GUIEnter autocommand to make this happen on startup
function FullScreenMaximize_Harmony()
  if has("macunix") && g:dock_hidden == 0
    call MacToggleDockHiding()
  endif
  winp 1 0
  set lines=59
  set columns=210
endfunction

function FullScreenMaximize_Bliss()
  if has("macunix") && g:dock_hidden == 0
    call MacToggleDockHiding()
  endif
  winp 0 0
  set lines=90
  set columns=317
endfunction

function NotepadWindowSize(widthfactor)
  set lines=50
  let &columns=88*a:widthfactor
endfunction

let Tlist_Ctags_Cmd = "/opt/local/bin/ctags"

" window settings for gvim
" please only put GUI based settings in this section...
" stuff that doesn't require the GUI to be running should go
" in the block above this one
if has("gui_running")
  call NotepadWindowSize(1)

  " use desert by default, and if we have it, use zackvim
  colo desert
  sil! colo zackvim

  set guioptions+=c
  set guioptions-=R " turn off the right scrollbar
  set guioptions-=L " turn off the left scrollbar
  if has("macunix")
    let __computername = MacGetComputerName()
    if __computername == "Euphoria"
      winp 351 187
    elseif __computername == "Bliss"
      winp 461 262
    elseif __computername == "Harmony"
      "winp 1 0
      " we need to use an autocommand to make this magic happen because
      " Vim hates it when we go out of desktop bounds before it loads the
      " freaking window
      "aug zcm_windows_maximize
      "au zcm_windows_maximize GUIEnter * set lines=59
      "au zcm_windows_maximize GUIEnter * set columns=210
      "au zcm_windows_maximize GUIEnter * call FullScreenMaximize_Harmony()
      "aug END
    elseif __computername == "Tim Menzies’s Mac mini"
    endif
  elseif has("gui_win32")
    " screw it, on windows we just maximize
    " NOT TODAY! --zack, on Windows 7 (uncomment to enable automaximiz3e)
    " aug zcm_windows_maximize
    " au zcm_windows_maximize GUIEnter * simalt ~x
    " aug END

    " also, kill win32 gvim's toolbar
    set guioptions-=T
    " and the tearoff menu items
    set guioptions-=t
    " and the standard menus themselves
    set guioptions-=m
    " and start from our My Documents (or other home) directory
    cd ~

    " set a font? (I'm cool with not doing this right now in Windows.)
    " set gfn=Lucida_Console:h10:cANSI
    " OMG CONSOLAS NOM NOM NOM
    set gfn=Consolas

    " find the ctags utility
    let Tlist_Ctags_Cmd = "c:\\cygwin\\bin\\ctags.exe"

    " If we're running on the Microsoft campus, then we want to do a few extra
    " things...
    if(substitute($USERDNSDOMAIN, "\w\+\.", "", "") == "CORP.MICROSOFT.COM")
    endif
  endif
endif

if has("dos32") || has("dos16")
  set viminfo+=nC:/VIM72/_viminfo
endif

" functions to make the window just like ma used to make

" function to make the window in the original starting position
function OriginalWindowPosition()
  if MacGetComputerName() == "Euphoria"
    winp 351 187
  elseif MacGetComputerName() == "Bliss"
    winp 461 262
  elseif MacGetComputerName() == "Harmony"
    winp 1 0
  else
    winp 5 25
  endif
endfunction

" function to make the window the original size
function OriginalWindowSize()
  if has("macunix") && g:dock_hidden == 0
    call MacToggleDockHiding()
  endif
  winp 5 25
  set lines=50
  set columns=160
endfunction

" function to do both of the above
function OriginalWindow()
  call OriginalWindowSize()
  call OriginalWindowPosition()
endfunction

" Disable the audible and visual bells
au VimEnter * set vb t_vb=

set backspace=2
syntax enable

" set custom syntaxes here
au BufNewFile,BufRead *.applescript set syn+=applescript

set number
set autoindent
au BufNewFile,BufRead *.java compiler javac
filetype on
filetype indent on
filetype plugin on

" lisp options
aug ClojureZCM
au ClojureZCM BufNewFile,BufRead *.clj set ft=lisp
au ClojureZCM BufNewFile,BufRead *.clj setlocal lw <
au ClojureZCM BufNewFile,BufRead *.clj setlocal lw+=catch,def,defn,defonce,doall
au ClojureZCM BufNewFile,BufRead *.clj setlocal lw+=dorun,doseq,dosync,doto
au ClojureZCM BufNewFile,BufRead *.clj setlocal lw+=monitor-enter,monitor-exit
au ClojureZCM BufNewFile,BufRead *.clj setlocal lw+=ns,recur,throw,try,var
au ClojureZCM BufNewFile,BufRead *.clj setlocal lw+=defn-,proxy
au ClojureZCM BufNewFile,BufRead *.clj setlocal lw-=do
au ClojureZCM BufNewFile,BufRead *.clj set lisp
aug END

" folding options
set foldcolumn=3
set fdn=2
"aug zcm_folding
"au zcm_folding BufNewFile,BufRead *.py,_vimrc,.vimrc set foldmethod=indent
"au zcm_folding BufNewFile,BufRead *.java,*.[ch],*.cpp,*.hpp set foldmethod=syntax
"au zcm_folding BufNewFile,BufRead * silent! %foldo!
"au zcm_folding BufNewFile,BufRead * let b:open_all_folds_bfbn=1
"au zcm_folding WinEnter __Tag_List__ set foldcolumn=0
"au zcm_folding Syntax java* syn region myfold start="{" end="}" transparent fold
"au zcm_folding Syntax java* syn sync fromstart
"aug END

" I just so happen to like Doxygen-style comments, so I'm going activate them by default here
" (but, of course, only for compatible files with an autocommand)
aug zcm_doxygen
au zcm_doxygen BufNewFile,BufRead * let b:zcm_doxified = 0
au zcm_doxygen BufNewFile,BufRead *.[ch],*.java,*.cpp,*.hpp call EnableDoxygenComments()
aug END

" netrw Explore sort options...
let g:netrw_sort_sequence="[\\/]$,\\.h$,\\.c$,\\.cpp$,\\.java$,\\.class$,\\.py$,\\.pyc$,\\.[a-np-z]$,Makefile,Doxyfile,*,\\.info$,\\.swp$,\\.o$,\\.obj$,\\.bak$"

let s:cpo_save=&cpo
set cpo&vim
map! <xHome> <Home>
map! <xEnd> <End>
map! <S-xF4> <S-F4>
map! <S-xF3> <S-F3>
map! <S-xF2> <S-F2>
map! <S-xF1> <S-F1>
map! <xF4> <F4>
map! <xF3> <F3>
map! <xF2> <F2>
map! <xF1> <F1>
map <xHome> <Home>
map <xEnd> <End>
map <S-xF4> <S-F4>
map <S-xF3> <S-F3>
map <S-xF2> <S-F2>
map <S-xF1> <S-F1>
map <xF4> <F4>
map <xF3> <F3>
map <xF2> <F2>
map <xF1> <F1>
let &cpo=s:cpo_save
unlet s:cpo_save

set report=1

" custom mappings
nmap <C-C><C-N> :set invnumber<CR>
inoremap <F5> <C-R>=strftime("%x %X %Z")<CR>
nnoremap <F5> "=strftime("%x %X %Z")<CR>P
inoremap <S-F5> <C-R>=strftime("%b %d, %Y")<CR>
nnoremap <S-F5> "=strftime("%b %d, %Y")<CR>P
nnoremap <C-F6> :call ToggleDoxygenComments()<CR>
nnoremap <F6> :TlistToggle<CR>

" taglist.vim options
let Tlist_Compact_Format=1
"let Tlist_Auto_Open=1
let Tlist_Process_File_Always=1
let Tlist_Exit_OnlyWindow=1
hi! link TagListFileName VisualNOS

set ut=10
" ts and sw need to be the same for << and >> to work correctly!
set ts=2
set sw=2
set ls=2
set tw=80

" always show the status line
" set laststatus=2

" only use spaces instead of tabs
set expandtab
