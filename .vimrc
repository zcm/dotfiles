set nocompatible
set showcmd

" detect if we're in restricted mode before doing anything else
let RESTRICTED_MODE=0
try
  call system("echo ...")
catch /^Vim\%((\a\+)\)\=:E145/
  let RESTRICTED_MODE=1
endtry

set rtp+=~/vimfiles,~/vimfiles/after

if has("persistent_undo")
  set undofile
  set undolevels=10000
endif

if has("gui_macvim")
  sil! set gfn=ProggySquare:h11
endif

if !has("win32") && match($TERM, "screen") != -1
  set term=xterm-256color
  let g:using_gnu_screen = 1
else
  let g:using_gnu_screen = 0
endif

" Override vim's terminal detection for GNOME Terminal (when not still running in a GNU screen).
if !has("gui_running") && has("unix") && $COLORTERM == 'gnome-terminal' && match($TERM, "screen") != -1
  set t_Co=256
endif

let g:dock_hidden = 0

" on Mac OS X, gets the computer name (not the host name)
if (!RESTRICTED_MODE && (has("macunix") || has("gui_macvim")))
  let g:maccomputernamestring = ""
  function MacGetComputerName()
    if g:maccomputernamestring == ""
      let g:maccomputernamestring = system("scutil --get ComputerName")
    endif
    return strpart(g:maccomputernamestring, 0, strlen(g:maccomputernamestring)-1)
  endfunction

  " on Mac OS X, toggle hiding the dock
  function MacToggleDockHiding()
    if has("autocmd")
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
    endif
    call system("osascript -e 'tell app \"System Events\" to keystroke \"d\" using {command down, option down}'")
  endfunction
endif

" these two functions allow the user to toggle between
" standard comments and Doxygen comments
function EnableDoxygenComments()
  let b:zcm_doxified = 1
  set syn+=.doxygen
endfunction
function DisableDoxygenComments()
  let b:zcm_doxified = 0
  set syn-=.doxygen
endfunction

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

function RecalculatePluginSplitWidth()
  let l:width=0
  if (&columns / 5 < 30)
    let l:width=30
  else
    let l:width=(&columns / 5)
  endif
  return l:width
endfunction

function RecalculatePluginSplitHeight()
  let l:height=0
  if &lines > 30
    let l:height=(&lines / 4 + 3)
  else
    let l:height=(&lines / 3)
  endif
  return l:height
endfunction

let MICROSOFT_CORP_SPECIFIC=0
let AMAZON_CORP_SPECIFIC=0
let GOOGLE_CORP_SPECIFIC=0

function CheckRunningAtGoogle()
  let l:domain_match=0
  if has("unix")
    let l:pattern="[a-zA-Z0-9_\\-]\\+\\.[a-zA-Z0-9_\\-]\\+\\."
    let l:domain=substitute(substitute(hostname(), l:pattern, "", ""), "[\s\n]\\+", "", "")
    let l:domain_match=(l:domain == "corp.google.com")
    if !l:domain_match && !g:RESTRICTED_MODE
      " for some reason, that didn't work... try through the shell if we can
      let l:domain=substitute(substitute(system("echo $HOSTNAME"), l:pattern, "", ""), "[\s\n]\\+", "", "")
      let l:domain_match=(l:domain == "corp.google.com")
    endif
  endif
  return l:domain_match
endfunction

if(has("unix") && substitute($HOSTNAME, "[a-zA-Z0-9_\\-]\\+\\.", "", "") == "desktop.amazon.com")
  let AMAZON_CORP_SPECIFIC=1
  if(filereadable("/apollo/env/envImprovement/var/vimrc"))
    so /apollo/env/envImprovement/var/vimrc
    set rtp+=~/vimfiles,~/vimfiles/after
  endif
elseif(CheckRunningAtGoogle())
  let GOOGLE_CORP_SPECIFIC=1
  if(!RESTRICTED_MODE && filereadable("/usr/share/vim/google/gtags.vim"))
    function Google_RecheckGtlistOrientationBounds()
      if (&columns > 162 || &lines < 49)
        let g:google_tags_list_orientation='vertical'
        let g:google_tags_list_height=''
        let g:google_tags_list_width=RecalculatePluginSplitWidth()
      else
        let g:google_tags_list_orientation='horizontal'
        let g:google_tags_list_width=''
        let g:google_tags_list_height=RecalculatePluginSplitHeight()
      endif
    endfunction
    function Google_GtlistIfNotHelp()
      if &syn == "help"
        exe 'tag ' . expand('<cword>')
      else
        exe 'Gtlist ' . expand('<cword>')
      endif
    endfunction
    function Google_GtjumpIfNotHelp()
      if &syn == "help"
        exe 'tjump ' . expand('<cword>')
      else
        exe 'Gtjump ' . expand('<cword>')
      endif
    endfunction
    aug ZCM_GoogleGtagsResize
    au ZCM_GoogleGtagsResize VimResized * call Google_RecheckGtlistOrientationBounds()
    aug END
    source /usr/share/vim/google/gtags.vim
    call Google_RecheckGtlistOrientationBounds()
    let g:google_tags_list_format='long'
    nnoremap <C-]> :call Google_GtlistIfNotHelp()<CR>
    nnoremap <C-W>] :tab split<CR>:call Google_GtjumpIfNotHelp()<CR>
    nnoremap <C-W><C-]> :tab split<CR>:call Google_GtjumpIfNotHelp()<CR>
    nnoremap <C-W>g<C-]> :vsp <CR>:call Google_GtjumpIfNotHelp()<CR>
  endif
  function Google_FindAndSetGoogle3Root(add_java_paths)
    let l:absolute=expand("%:p:h")
    let l:idx=stridx(absolute, "google3")
    if l:idx >= 0
      setlocal path<
      execute "setlocal path+=" . strpart(l:absolute,0,l:idx)
      execute "setlocal path+=" . strpart(l:absolute,0,l:idx) . "google3"
      if a:add_java_paths
        execute "setlocal path+=" . strpart(l:absolute,0,l:idx) . "google3/java"
        execute "setlocal path+=" . strpart(l:absolute,0,l:idx) . "google3/javatests"
      endif
    endif
  endfunction
  aug ZCM_SetGoogle3PathRoot
  au ZCM_SetGoogle3PathRoot BufEnter * call Google_FindAndSetGoogle3Root(0)
  au ZCM_SetGoogle3PathRoot BufEnter *.java call Google_FindAndSetGoogle3Root(1)
  aug END
elseif((has("win32") || has("win64")) && substitute($USERDNSDOMAIN, "\\w\\+\\.", "", "") == "CORP.MICROSOFT.COM")
  let MICROSOFT_CORP_SPECIFIC=1
endif

if MICROSOFT_CORP_SPECIFIC && ((has("win32") || has("win64")) && !has("win95"))
  " Saving my undofiles alongside sourcefiles breaks my cleansrc step in
  " ohome at MS, so I need to put it somewhere else in order to make sure
  " that my build doesn't break.
  if !isdirectory($APPDATA . "\\vimundodata")
    call mkdir($APPDATA . "\\vimundodata")
  endif
  set undodir="$APPDATA\vimundodata"
endif

if !RESTRICTED_MODE
  function CheckIsCtagsExuberant()
    let l:is_exuberant = 0
    " if cases copied from taglist.vim --zack
    if exists('g:Tlist_Ctags_Cmd')
      let l:cmd = g:Tlist_Ctags_Cmd
    elseif executable('exuberant-ctags')
      " On Debian Linux, exuberant ctags is installed
      " as exuberant-ctags
      let l:cmd = 'exuberant-ctags'
    elseif executable('exctags')
      " On Free-BSD, exuberant ctags is installed as exctags
      let l:cmd = 'exctags'
    elseif executable('ctags')
      let l:cmd = 'ctags'
    elseif executable('ctags.exe')
      let l:cmd = 'ctags.exe'
    elseif executable('tags')
      let l:cmd = 'tags'
    endif
    if exists("l:cmd")
      let l:version_output = system(l:cmd . " --version")
      let l:is_exuberant = l:is_exuberant || (stridx(l:version_output, "Exuberant") >= 0)
      let l:is_exuberant = l:is_exuberant || (stridx(l:version_output, "exuberant") >= 0)
      if !l:is_exuberant
        let l:version_output = system('"'. l:cmd . '" --version')
        let l:is_exuberant = l:is_exuberant || (stridx(l:version_output, "Exuberant") >= 0)
        let l:is_exuberant = l:is_exuberant || (stridx(l:version_output, "exuberant") >= 0)
      endif
    endif
    return l:is_exuberant
  endfunction
  function RecheckTaglistOrientationBounds()
    if (&columns > 162 || &lines < 49)
      let g:Tlist_Use_Horiz_Window=0
      let g:Tlist_WinWidth=RecalculatePluginSplitWidth()
    else
      let g:Tlist_Use_Horiz_Window=1
      let g:Tlist_WinHeight=RecalculatePluginSplitHeight()
    endif
  endfunction
endif

" Find the ctags command
if (!AMAZON_CORP_SPECIFIC && !GOOGLE_CORP_SPECIFIC)
  if has("unix")
    if filereadable("/opt/local/bin/ctags") " This is the MacPorts case, I think?
      let g:Tlist_Ctags_Cmd = "/opt/local/bin/ctags"
    endif
  elseif (has("win32") || has("win64") || has("win95"))
    " find the ctags utility
    if filereadable($HOME . "\\vimfiles\\bin\\ctags.exe")
      let g:Tlist_Ctags_Cmd = '"' . $HOME . '\\vimfiles\\bin\\ctags.exe"'
    elseif filereadable("c:\\cygwin\\bin\\ctags.exe")
      let g:Tlist_Ctags_Cmd = "c:\\cygwin\\bin\\ctags.exe"
    endif
  endif
endif

if has("dos32") || has("dos16")
  set viminfo+=nC:/VIM72/_viminfo
endif

" functions to make the window just like ma used to make

" function to make the window in the original starting position
if !RESTRICTED_MODE
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
endif

" This section should be used for custom mappings and personal editor settings,
" before we start taking changes from our environment (e.g. Google).

" netrw Explore sort options...
let g:netrw_sort_sequence="[\\/]$,\\.h$,\\.c$,\\.cpp$,\\.java$,\\.class$,\\.py$,\\.pyc$,\\.[a-np-z]$,Makefile,Doxyfile,*,\\.info$,\\.swp$,\\.o$,\\.obj$,\\.bak$"

set backspace=2

set number
set autoindent

filetype on
filetype indent on
filetype plugin on

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

" custom mappings
nmap <C-C><C-N> :set invnumber<CR>
inoremap <F5> <C-R>=strftime("%x %X %Z")<CR>
nnoremap <F5> "=strftime("%x %X %Z")<CR>P
inoremap <S-F5> <C-R>=strftime("%b %d, %Y")<CR>
nnoremap <S-F5> "=strftime("%b %d, %Y")<CR>P
nnoremap <C-F7> :call ToggleDoxygenComments()<CR>

hi! link TagListFileName VisualNOS

"hi Pmenu ctermfg=7 ctermbg=5
"hi PmenuSel ctermfg=5 ctermbg=6

if filereadable($VIMRUNTIME . "/macros/matchit.vim")
  source $VIMRUNTIME/macros/matchit.vim
endif

" and here, if we're running at Google, we will take their changes
" (override Google stuff by putting commands after this call)
if GOOGLE_CORP_SPECIFIC && filereadable("/usr/share/vim/google/google.vim")
  source /usr/share/vim/google/google.vim
endif

" Fire up Pathogen and IPI so we can chainload package managers.
call pathogen#infect()
call ipi#inspect()

" Time to kickstart Vundle using IPI... god what a hack
IP vundle

filetype off " do NOT start vundle with this on!
call vundle#rc("$HOME/vimfiles/ipi")

function IsBundleInstalled(bundle_name)
  return IsBundleInstalledWithAutoload(a:bundle_name, a:bundle_name)
endfunction

function IsBundleInstalledWithAutoload(bundle_name, autoload_target)
  return IsBundleInstalledWithSomeFile(a:bundle_name, "autoload/" . a:autoload_target)
endfunction

function IsBundleInstalledWithSomeFile(bundle_name, target)
  return filereadable($HOME . "/vimfiles/ipi/" . a:bundle_name . "/".  a:target)
endfunction

function ZackBundleGetGitUserOrUrl(items)
  let github_user_or_git_url = ''
  let current = 0
  for item in a:items
    if current == len(a:items) - 1
      break
    elseif current != 0
      let github_user_or_git_url = github_user_or_git_url . '/'
    endif
    let github_user_or_git_url = github_user_or_git_url . item
    let current = current + 1
  endfor
  return github_user_or_git_url
endfunction

let s:queued_bundles = []
let s:processing_queued_bundles = 0

function ProcessQueuedZackBundles() abort
  let s:processing_queued_bundles = 1
  for each in s:queued_bundles
    call ZackBundle(each[0], each[1], each[2], each[3])
  endfor
endfunction

" NOTE: use force_ipi to inject plugins DURING .vimrc execution -- this means
" you can check for existence of plugin functions and do feature detection. If
" you don't do this, use RTP instead

function ZackBundle(...) abort
  if len(a:000) == 1
    if stridx(a:1, '/') == -1
      call ZackBundle(a:1, '')
    else
      let items = split(a:1, '/')
      let github_user_or_git_url = ZackBundleGetGitUserOrUrl(items)
      call ZackBundle(github_user_or_git_url, items[len(items)-1], 0)
    endif
  elseif len(a:000) == 2
    let a2_is_load_method = (string(a:2) != string(0) && (a:2 == 'normal' || a:2 == 'force_ipi' || a:2 == 'disable'))
    if stridx(a:1, '/') != -1 && (stridx(a:2, ".vim") != -1 || a2_is_load_method)
      let items = split(a:1, '/')
      let github_user_or_git_url = ZackBundleGetGitUserOrUrl(items)
      call ZackBundle(github_user_or_git_url, items[len(items)-1], a:2)
    elseif stridx(a:1, '/') == -1 && (stridx(a:2, ".vim") != -1 || a2_is_load_method)
      call ZackBundle(a:1, '', a:2)
    else
      call ZackBundle(a:1, a:2, 0)
    endif
  elseif len(a:000) == 3
    let a3_is_load_method = (string(a:3) != string(0) && (a:3 == 'normal' || a:3 == 'force_ipi' || a:3 == 'disable'))
    if a3_is_load_method
      call ZackBundle(a:1, a:2, 0, a:3)
    else
      call ZackBundle(a:1, a:2, a:3, 'normal')
    endif
  elseif len(a:000) == 4
    " Do real work now
    let bundle_target = a:1 . (a:2 != '' ? '/' . a:2 : '')
    let bundle_name = a:2 == '' ? a:1 : a:2
    let bundle_name_parts = split(a:2, '.')
    let load_method = a:4
    if stridx(a:3, ".vim") != -1
      " If we have a load condition, we have to force IPI loading method
      let load_method = 'force_ipi'
    endif
    if len(bundle_name_parts) > 0
      let bundle_name = bundle_name_parts[0]
    endif
    if load_method == 'normal' || s:processing_queued_bundles
      let l:rtp_save = &rtp
      Bundle bundle_target
      let l:bundle_rtp = &rtp
      let &rtp = l:rtp_save
    endif
    " If we don't end up loading the plugin here, the user can do it manually
    " later with :IP <bundle name>.
    if load_method == 'normal'  " if a:4 is true, go ahead and load the plugin...
      " This is the 'normal' way to load the plugin, using rtp.
      let &rtp = l:bundle_rtp
    elseif load_method == 'force_ipi'
      " We can force the plugin to load using IPI if we want.
      if s:processing_queued_bundles
        if stridx(a:3, ".vim") != -1
          if stridx(a:3, '/') == -1
            if IsBundleInstalledWithAutoload(bundle_name, a:3)
              execute 'IP ' . bundle_name
            endif
          else
            if IsBundleInstalledWithSomeFile(bundle_name, a:3)
              execute 'IP ' . bundle_name
            endif
          endif
        else
          if isdirectory($HOME . "/vimfiles/ipi/" . bundle_name)
            execute 'IP ' . bundle_name
          endif
        endif
      else
        " We need to queue force_ipi and disabled bundles so that they don't get
        " regenerated by RTP and so that they load last. This prevents them
        " from loading twice. To process these, call ProcessQueuedZackBundles().
        call add(s:queued_bundles, a:000)
      endif
    elseif load_method == 'disabled' && !s:processing_queued_bundles
      call add(s:queued_bundles, a:000)
    endif
  endif
  " I guess we can just ignore if we give it 0 or >4 args
endfunction

" Vundle bundles go here (and other packages too, say, Glug/Pathogen)

" absolutely completely required
Bundle 'gmarik/vundle'

" other bundles...
" YCM should probably come last... YOUCOMPLETEME IS HARD OKAY (okay, so maybe first...)
let PLAN_TO_USE_YCM_OMNIFUNC = 0
if (version >= 703 && has('patch584')) || version > 703   " You need Vim 7.3.584 or better for YCM...
  if GOOGLE_CORP_SPECIFIC
    " Can't make system calls in restricted mode, so we won't update in this case.
    if !RESTRICTED_MODE
      function UpdateGoogleYcmBinaries()
        let ycm_core = "/google/data/ro/users/st/strahinja/ycm_core.so"
        let libclang = "/google/data/ro/users/kl/klimek/libclang.so"
        if filereadable(ycm_core) && isdirectory($HOME . "/vimfiles/ipi/YouCompleteMe/python")
          call system("cp " . ycm_core . " " . $HOME . "/vimfiles/ipi/YouCompleteMe/python/")
        endif
        if filereadable(libclang) && isdirectory($HOME . "/vimfiles/ipi/YouCompleteMe/python")
          call system("cp " . libclang . " " . $HOME . "/vimfiles/ipi/YouCompleteMe/python/")
        endif
      endfunction
      let local_ycm = $HOME . "/vimfiles/ipi/YouCompleteMe/python/ycm_core.so"
      let local_clang = $HOME . "/vimfiles/ipi/YouCompleteMe/python/libclang.so"
      if !filereadable(local_ycm) || !filereadable(local_clang)
        call UpdateGoogleYcmBinaries()
      endif
    endif
    " might consider doing this magic outside of google too...
  endif
  let PLAN_TO_USE_YCM_OMNIFUNC = 1
  call ZackBundle('Valloric/YouCompleteMe', 'youcompleteme.vim')
endif

call ZackBundle('gmarik/ingretu')
call ZackBundle('xoria256.vim')
call ZackBundle('altercation/vim-colors-solarized')
call ZackBundle('tpope/vim-vividchalk')
"call ZackBundle('javacomplete', 'force_ipi')

if (version >= 703 && has('patch661')) || version > 703
  " These look awful on the terminal with unpatched fonts. Maybe I'll get to
  " supporting this in the future. Or something. --zack
  "call ZackBundle('Lokaltog/powerline')
  "set rtp+=$HOME/vimfiles/ipi/powerline/powerline/bindings/vim
endif

if (!RESTRICTED_MODE && CheckIsCtagsExuberant())
  nnoremap <F7> :TlistToggle<CR>
  " taglist.vim options
  let Tlist_Compact_Format=1
  "let Tlist_Auto_Open=1
  let Tlist_Process_File_Always=1
  let Tlist_Exit_OnlyWindow=1
  aug ZCM_TaglistResize
  au ZCM_TaglistResize VimResized * call RecheckTaglistOrientationBounds()
  aug END
  call RecheckTaglistOrientationBounds()
  " we delay loading of the taglist plugin because it's slow and annoying if you
  " don't have exuberant ctags or the wrong ctags installed (throws errors every
  " time you open a file)
  call ZackBundle('taglist.vim', 'force_ipi')
endif

call ZackBundle('tpope/vim-scriptease')
call ZackBundle('tpope/vim-dispatch')

if has("python")
  call ZackBundle('Valloric/MatchTagAlways')
endif

let g:syntastic_check_on_open=1
call ZackBundle('scrooloose/syntastic', 'force_ipi')

" Don't touch this...
call ProcessQueuedZackBundles()

" Glug packages...
if GOOGLE_CORP_SPECIFIC
  Glug blaze
  Glug g4
  Glug syntastic-google

  " Extra google-specific config opts
  let g:syntastic_java_checkers = ['glint']
  let g:syntastic_borg_checkers = ['borgcfg']
  let g:syntastic_gcl_checkers = ['gcl']
  let g:syntastic_python_checkers = ['pyflakes']

  let g:blazevim_execution = 'foreground' " until background is fixed...

  " Blaze hotkeys
  " Load errors from blaze
  nnoremap ,be :call blaze#LoadErrors()<cr>:botright cw<cr>
  " View build log
  nnoremap ,bl :call blaze#ViewCommandLog()<cr>
  " Run blaze on targets
  nnoremap ,bd :call blaze#BuildOrTestTargets()<cr>
  " Run 'update deps' on targets
  nnoremap ,bu :call blaze#UpdateTargetDeps()<cr>
  " Run 'blaze build'
  nnoremap ,bb :call blaze#BuildTargets()<cr>
  " Run 'blaze test'
  nnoremap ,bt :call blaze#TestTargets()<cr>
  " Run 'blaze test' on the current file (only interesting for Java)
  nnoremap ,bc :call blaze#TestCurrentFile()<cr>
  " Run 'blaze test' on the current test method.
  nnoremap ,bm :call blaze#TestCurrentMethod()<cr>
endif

" End bundle section

" Color and window settings section
if !RESTRICTED_MODE
  colo elflord " default for if we set nothing else ever
  if !has("win32") || has("gui_running")
    " oh god please no, not in cmd.exe. it literally looks like poop everywhere
    sil! colo vividchalk " this thing is sweet
  endif
endif

" window settings for gvim
" please only put GUI based settings in this section...
" stuff that doesn't require the GUI to be running should go
" in the block above this one
if has("gui_running")
  " use desert by default, and if we have it, use zackvim
  colo desert
  sil! colo dante
  sil! colo vividchalk " this thing is sweet
  sil! colo zackvim

  set guioptions+=c
  set guioptions-=R " turn off the right scrollbar
  set guioptions-=L " turn off the left scrollbar

  if has("unix") || has("gui_win32")
    " also, kill win32/unix gvim's toolbar
    set guioptions-=T
    " and the tearoff menu items
    set guioptions-=t
    " and the standard menus themselves
    set guioptions-=m
  endif

  " Set window position and size
  if has("unix")
    if GOOGLE_CORP_SPECIFIC
      if match(hostname(), "zmurray-linux.kir") != -1
        set lines=90
        set columns=154
        winp 0 0
      endif
    else
      call NotepadWindowSize(1)
    endif
  elseif has("macunix")
    if !RESTRICTED_MODE
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
    endif
  elseif has("gui_win32")
    " screw it, on windows we just maximize
    " NOT TODAY! --zack, on Windows 7 (uncomment to enable automaximiz3e)
    " aug zcm_windows_maximize
    " au zcm_windows_maximize GUIEnter * simalt ~x
    " aug END

    " and start from our My Documents (or other home) directory
    cd ~

    " set a font? (I'm cool with not doing this right now in Windows.)
    " set gfn=Lucida_Console:h10:cANSI
    " OMG CONSOLAS NOM NOM NOM
    sil! set gfn=Consolas

    " If we're running on the Microsoft campus, then we want to do a few extra
    " things...
    if MICROSOFT_CORP_SPECIFIC
      " Microsoft does not obey the 80 character limit, so the window should
      " really be bigger. Double ought to do it. --zack
      call NotepadWindowSize(2)
    endif
  else
    " If we don't have any idea what is going on or where we are...
      call NotepadWindowSize(1)
  endif
endif

" End color and window settings section


" Autocommand section -- goes after bundle section since autocommands may
" depend on bundle settings
if has("autocmd")
  " Disable the audible and visual bells
  au VimEnter * set vb t_vb=

  " set custom syntaxes here, before syntax enable
  au BufNewFile,BufRead *.applescript set syn+=applescript

  if MICROSOFT_CORP_SPECIFIC
    au BufWinEnter,BufNewFile,BufRead *.err set ft=err
    au BufWinEnter,BufNewFile,BufRead *.wrn set ft=wrn
    au! Syntax err
    au Syntax err runtime! syntax/err.vim
    au! Syntax wrn
    au Syntax wrn runtime! syntax/wrn.vim
  endif

  " Fix terminal timeout when pressing escape to leave insert mode
  if !has("gui_running")
    set ttimeoutlen=10
    aug FastEscape
    autocmd!
    au InsertEnter * set timeoutlen=0
    au InsertLeave * set timeoutlen=1000
    aug END
  endif

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
  "set foldcolumn=3
  "set fdn=2
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

  " Exclude vimrc from undofile overrides since our copy is under source control
  aug zcm_vimrc_prevent_undofile_override
  au zcm_vimrc_prevent_undofile_override BufNewFile,BufReadPre .vimrc sil! setlocal undodir=.
  au zcm_vimrc_prevent_undofile_override BufNewFile,BufReadPre _vimrc sil! setlocal undodir=.
  aug END

  au QuickFixCmdPost,BufWinEnter,BufWinLeave * if &buftype == 'quickfix' | setlocal nonumber | endif

  if GOOGLE_CORP_SPECIFIC
    if !PLAN_TO_USE_YCM_OMNIFUNC && exists('*GtagOmniCompletion')
      aug ZCM_GoogleGtagsOmniCompletion
      au ZCM_GoogleGtagsOmniCompletion BufEnter * set omnifunc=GtagOmniCompletion
      aug END
    endif
    " This might be the slightest bit of a google-specific hack, but I want ,bl
    " to have nonumber set
    au FileReadPost * if &buftype == 'nofile' | setlocal nonumber | endif
  else
    au BufNewFile,BufRead *.java compiler javac
  endif
  " This appears to be a bug in Vim -- submodule functions are not visible to
  " exists() until after the first time they are called, which is weird.
  " Silently attempt an invalid call in order to workaround this bug...
  sil! call javacomplete#Complete()
  if exists('*javacomplete#Complete')
    aug ZCM_UseJavaCompleteWhenAvailable
    au Filetype java setlocal omnifunc=javacomplete#Complete
    aug END
  endif
endif

" End autocommand section


if !RESTRICTED_MODE
  syntax enable
endif

set report=1

set ut=10

" ts and sw need to be the same for << and >> to work correctly!
set ts=2
set sw=2

" always show the status line
set ls=2
set stl=%<%f\ #%{changenr()}
if exists('*SyntasticStatuslineFlag')
  set stl+=\ %#warningmsg#%{SyntasticStatuslineFlag()}%*
endif
set stl+=\ %h%m%r%=%-14.(%l,%c%V%)\ %P

if MICROSOFT_CORP_SPECIFIC != 1
  set tw=80
endif

" only use spaces instead of tabs
set expandtab

if GOOGLE_CORP_SPECIFIC
  " make sure this is just about the last line in the file, especially for corp-specific modes
  set nomodeline " this is to absolutely stop security vulnerabilities with nocompatible
endif

let g:ZM_vimrc_did_complete_load=1

" vim:ai:et:ts=2:sw=2:tw=80
