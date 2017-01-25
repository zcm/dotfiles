if has('vim_starting')
  if !has('nvim')
    set nocompatible

    if !has("win32") && match($TERM, "screen") != -1
      set term=xterm-256color
      let g:using_gnu_screen = 1
    else
      let g:using_gnu_screen = 0
    endif

    " Override vim's terminal detection for GNOME Terminal (when not still running
    " in a GNU screen).
    if !has("gui_running") && has("unix")
          \ && $COLORTERM == 'gnome-terminal' && match($TERM, "screen") != -1
      set t_Co=256
    endif
  endif

  set showcmd

  " detect if we're in restricted mode before doing anything else
  sil! call writefile([], '')
  let RESTRICTED_MODE = (v:errmsg =~# '^E145:')

  if has("persistent_undo")
    set undofile
    set undolevels=10000
  endif

  if (has("win32") || has("win64") || has("win95"))
    let s:stdhome=$USERPROFILE
    let s:vimfiles_dir=s:stdhome . "\\vimfiles"
    exe 'set rtp+="'.s:stdhome.'\vimfiles","'.s:stdhome.'\vimfiles\after"'
  else
    let s:stdhome=$HOME
    let s:vimfiles_dir=s:stdhome . "/vimfiles"
    set rtp+=~/vimfiles,~/vimfiles/after
  endif

  let g:zcm_has_jobs = has('job') && (v:version > 704 || v:version == 704
        \ && (has('unix') && has('patch1274')
        \ || (has('win32') || has('win64')) && has('patch1530')))

  if has("gui_running")
    if has("gui_macvim")
      sil! set gfn=ProggySquare:h11
      sil! set gfn=PragmataPro:h13
    elseif has("gui_gtk")
      sil! set gfn=ProggySquareTT\ 12
      sil! set gfn=PragmataPro\ 10
    elseif has("gui_win32")
      sil! set gfn=Consolas
      sil! set gfn=ProggySquareTT:h12
      sil! set gfn=PragmataPro:h10
    endif
  endif
endif

let g:zcm_feature_explanations = {}
let g:zcm_feature_explain_key_order = []

function! ExplainFeature(isavailable, type, name, reason)
  let l:featurename = "Unknown feature type "

  if a:type ==? "au"
    let l:featurename = "Autocommand "
  elseif a:type ==? "function"
    let l:featurename = "Function "
  elseif a:type ==? "plugin"
    let l:featurename = "Plugin "
  elseif a:type ==? "generic"
    let l:featurename = ""
  endif

  let l:featurename = l:featurename . a:name

  if a:isavailable
    let l:featurename = l:featurename . " was loaded because "
  else
    let l:featurename = l:featurename . " is missing because "
  end

  if has_key(g:zcm_feature_explanations, l:featurename)
    call add(g:zcm_feature_explanations[l:featurename], a:reason)
  else
    let g:zcm_feature_explanations[l:featurename] = [a:reason]
    call add(g:zcm_feature_explain_key_order, l:featurename)
  endif
endfunction

function! DisplayExplanations()
  if len(keys(g:zcm_feature_explanations)) == 0
    echom "There are no explanations."
    return
  endif

  for key in g:zcm_feature_explain_key_order
    let l:reasons = g:zcm_feature_explanations[key]
    if len(l:reasons) == 1
      echom key . l:reasons[0] . "."
    elseif len(l:reasons) > 1
      let l:first = 1
      let l:finalreason = ""
      let l:countdown = len(l:reasons)
      for each in l:reasons
        let l:countdown = l:countdown - 1
        if l:first
          let l:finalreason = each
          let l:first = 0
        else
          if l:countdown == 0
            let l:finalreason = l:finalreason . ", and " . each
          else
            let l:finalreason = l:finalreason . ", " . each
          endif
        endif
      endfor
      echom key . l:finalreason . "."
    endif
  endfor
endfunction

function! ExplainPythonFeature(isavailable, type, name)
  if a:isavailable
    call ExplainFeature(1, a:type, a:name,
          \ "either vim feature 'python' or 'python3' is available")
  else
    call ExplainFeature(0, a:type, a:name,
          \ "neither vim feature 'python' nor 'python3' is available")
  endif
endfunction

" these two functions allow the user to toggle between
" standard comments and Doxygen comments
function! EnableDoxygenComments()
  let b:zcm_doxified = 1
  set syn+=.doxygen
endfunction

function! DisableDoxygenComments()
  let b:zcm_doxified = 0
  set syn-=.doxygen
endfunction

function! ToggleDoxygenComments()
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

function! NotepadWindowSize(widthfactor)
  call BaseNotepadWindowSize(88, a:widthfactor)
endfunction

function! JavaNotepadWindowSize(widthfactor)
  call BaseNotepadWindowSize(110, a:widthfactor)
endfunction

function! BaseNotepadWindowSize(basewidth, widthfactor)
  let &lines = a:basewidth * 100 / 88 * 50 / 100
  let &columns = a:basewidth * a:widthfactor
endfunction

function! RecalculatePluginSplitWidth()
  let l:width=0
  if (&columns <= 130)
    let l:width = 30
  else
    let l:width = 30 + (&columns - 130) * 2 / 5
    if l:width > 60
      let l:width = 60
    endif
  endif
  return l:width
endfunction

function! RecalculatePluginSplitHeight()
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
let AGILYSYS_CORP_SPECIFIC=0

if !filereadable(s:stdhome . "/.vimrc_skip_company_detection")
  " this is getting out of hand... this might be nice to move into a 'company detector' module...
  let AGILYSYS_CORP_SPECIFIC=filereadable(s:stdhome . "/.vimrc_agilysys")

  function! CheckRunningAtGoogle()
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

  function! CheckRunningAtAmazon()
    let l:domain_match = 0
    if has("unix")
      let l:hostname = $HOSTNAME

      if (l:hostname == "")
        let l:hostname = hostname()
      endif

      let l:pattern = "[a-zA-Z0-9_\\-]\\+\\."
      let l:domain = substitute(l:hostname, l:pattern, "", "")

      let l:domain_match =
        \ l:domain == "desktop.amazon.com" || l:domain == "ant.amazon.com"
    endif
    return l:domain_match
  endfunction

  if(CheckRunningAtAmazon())
    let AMAZON_CORP_SPECIFIC=1
    " Just take the runtime hooks. (Edit: No, don't even do this. Avoid loading
    " these ancient plugins AT ALL COSTS.)
    "if filereadable("/apollo/env/envImprovement/var/vimruntimehook")
      " Before sourcing Amazon's runtime hook, set a hack to avoid loading
      " SuperTab, which is pretty much the worst because it conflicts with
      " NeoComplCache.
      "let complType="DO_NOT_USE_EVER"
      " Just get rid of most/all of the plugins. I never use them and they're
      " annoying.
      "let loaded_bufexplorer=1
      "so /apollo/env/envImprovement/var/vimruntimehook
      "set rtp+=~/vimfiles,~/vimfiles/after
    "endif
    " Instead, do this customized load to get everything but the plugins:
    let g:ApolloRoot = "/apollo/env/envImprovement"
    set rtp+=$HOME/.vim
    set rtp+=/apollo/env/envImprovement/vim/amazon/brazil-config
    set rtp+=/apollo/env/envImprovement/vim/amazon/brazil_inc_path
    set rtp+=/apollo/env/envImprovement/vim/amazon/dat
    set rtp+=/apollo/env/envImprovement/vim/amazon/FLLog
    set rtp+=/apollo/env/envImprovement/vim/amazon/ion
    set rtp+=/apollo/env/envImprovement/vim/amazon/mail-after
    set rtp+=/apollo/env/envImprovement/vim/amazon/mosel
    set rtp+=/apollo/env/envImprovement/vim/amazon/object
    set rtp+=/apollo/env/envImprovement/vim/amazon/Perforce
    set rtp+=/apollo/env/envImprovement/vim/amazon/s3
    set rtp+=/apollo/env/envImprovement/vim/amazon/syntax-override-mason
    set rtp+=/apollo/env/envImprovement/vim/amazon/syntax-override-perl
    set rtp+=/apollo/env/envImprovement/vim/amazon/syntax-override-ruby
    if !RESTRICTED_MODE
      set rtp+=/apollo/env/envImprovement/vim/amazon/wiki_browser
    endif
    "set rtp+=/apollo/env/envImprovement/vim  " <-- evil plugins here
    set rtp+=$VIMRUNTIME
    set rtp+=/apollo/env/envImprovement/vim/amazon/mail-after/after
    "set rtp+=/apollo/env/envImprovement/vim/after  " <-- here too
    set rtp+=$HOME/.vim/after
    set rtp+=~/vimfiles,~/vimfiles/after
  elseif(CheckRunningAtGoogle())
    let GOOGLE_CORP_SPECIFIC=1
    if(!RESTRICTED_MODE && filereadable("/usr/share/vim/google/gtags.vim"))
      function! Google_RecheckGtlistOrientationBounds()
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
      function! Google_GtlistIfNotHelp()
        if &syn == "help"
          exe 'tag ' . expand('<cword>')
        else
          exe 'Gtlist ' . expand('<cword>')
        endif
      endfunction
      function! Google_GtjumpIfNotHelp()
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
    function! Google_FindAndSetGoogle3Root(add_java_paths)
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
endif

" Custom undodir settings
if has("persistent_undo")
  if has('unix')
    if AMAZON_CORP_SPECIFIC
      if !isdirectory(s:stdhome . '/.vim_undo')
        call mkdir(s:stdhome . '/.vim_undo')
      endif
      exe 'set undodir='.s:stdhome.'/.vim_undo'
    endif
  endif
endif

" Other custom directories -- use non-local paths for temp files if possible
if has("unix")
  set dir=~/tmp//,/var/tmp//,/tmp//,.
elseif has("win32") || has("win64") || has("win16") || has("win95") || has("dos32") || has("dos16")
  set dir=c:\tmp//,c:\temp//
  if has("win32") || has("has64")
    set dir+=$LOCALAPPDATA\Temp//
  endif
  set dir+="."
elseif has("amiga")
  set dir=t:,.
endif

if !RESTRICTED_MODE
  function! CheckIsCtagsExuberant()
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
  function! RecheckTaglistOrientationBounds()
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
    if filereadable(s:vimfiles_dir . "\\bin\\ctags.exe")
      let g:Tlist_Ctags_Cmd = '"' . s:vimfiles_dir . '\\bin\\ctags.exe"'
    elseif filereadable("c:\\cygwin\\bin\\ctags.exe")
      let g:Tlist_Ctags_Cmd = "c:\\cygwin\\bin\\ctags.exe"
    endif
  endif
endif

" Helper function for below. Might be nice to have this standalone.
function! SearchParentDirectoriesForFile(filename)
  let l:last = getcwd()
  let l:current = fnamemodify(l:last, ':h')
  return SearchParentDirectoriesForFileFrom(a:filename, l:last, l:current)
endfunction

function! SearchParentDirectoriesForFileFrom(filename, last, current)
  let l:last = a:last
  let l:current = a:current
  let l:sep = '/'
  if has("win32") || has("win64") || has("win16") || has("win95") || has("dos32") || has("dos16") || has("os2")
    let l:sep = '\'
  endif
  while l:current != l:last
    if isdirectory(l:current)
      let l:currentfile = l:current . l:sep . a:filename
      if filereadable(l:currentfile)
        return l:currentfile
      endif
    endif
    let l:last = l:current
    let l:current = fnamemodify(l:last, ':h')
  endwhile
  return -1
endfunction

function! MaybeUpdateGlobal()
  if g:zcm_gtags_known
    let l:last = expand('%:p')
    let l:current = expand('%:p:h')
    let l:file = SearchParentDirectoriesForFileFrom("GTAGS", l:last, l:current)
    if l:file != -1
      let l:dir = shellescape(fnamemodify(l:file, ":h"))
      if g:zcm_has_jobs
        sil! call job_start(
              \ ['/bin/sh', '-c', 'cd ' . l:dir . ' && global -u'])
      else
        sil! call system("pushd " . l:dir . " && global -u && popd")
      endif
    endif
  endif
endfunction

if !GOOGLE_CORP_SPECIFIC
  if has("cscope")
    set cscopetag
    set nocsverb
    let g:zcm_gtags_known=0
    if executable("gtags-cscope")
      " Not to be confused with Google's Gtags, I assure you.
      set csprg=gtags-cscope
      if filereadable("GTAGS")
        cs add GTAGS
        let g:zcm_gtags_known=1
      else
        " If the index isn't in the current directory, it could be in a parent.
        let s:parent_gtags_file = SearchParentDirectoriesForFile("GTAGS")
        if s:parent_gtags_file != -1 && filereadable(s:parent_gtags_file)
          exe "cs add " . s:parent_gtags_file
          let g:zcm_gtags_known=1
        endif
      endif
      if has('autocmd') && executable('global')
        aug ZCM_AutoGlobalUpdate
          au ZCM_AutoGlobalUpdate BufWritePost * sil! call MaybeUpdateGlobal()
        aug END
      endif
    else
      if filereadable("cscope.out")
        cs add cscope.out
      elseif $CSCOPE_DB != ""
        cs add $CSCOPE_DB
      endif
    endif
    set csverb
  endif
endif

if has("dos32") || has("dos16")
  set viminfo+=nC:/VIM72/_viminfo
endif

" probably like exactly none of this works on win9x...
if (!RESTRICTED_MODE) && (has("win32") || has("win64")) && !has("win95")
  function! RunInChainloadBatchFile(cmd)
    let l:tempbatchfile = fnamemodify(tempname(), ':h') . '\batch.cmd'
    exe 'redir! > ' . l:tempbatchfile
    sil echo a:cmd
    redir END
    let l:batch_cmd = '"' . l:tempbatchfile . '"'
    echom "Running in batch file: " . a:cmd
    call system(l:batch_cmd)
    if exists('l:tempbatchfile')
      call delete(l:tempbatchfile)
    endif
  endfunction

  function! AttemptToInstallMsysGit()
    if !executable("git") " Git is not available... we can try to install it maybe?
      let l:wgetcmd = s:vimfiles_dir . '\bin\wget.exe'
      if executable(l:wgetcmd)
        let l:MsysSetupExe = "Git-1.8.1.2-preview20130201.exe"
        let l:MsysGitUrl = "https://msysgit.googlecode.com/files/" . l:MsysSetupExe
        let l:Temp = shellescape($TMP)
        echom "Attempting to fetch " . l:MsysGitUrl . "..."
        call RunInChainloadBatchFile('"'.l:wgetcmd.'" --no-check-certificate -P '.lTemp.' '.l:MsysGitUrl)
        echom "Attempting to start setup..."
        call RunInChainloadBatchFile(shellescape($TMP . '\' . l:MsysSetupExe))
        if filereadable(l:MsysSetupExe)
          call delete(l:MsysSetupExe)
        endif
      endif
    endif
  endfunction
endif

" This section should be used for custom mappings and personal editor settings,
" before we start taking changes from our environment (e.g. Google).

" netrw Explore sort options...
let g:netrw_sort_sequence="[\\/]$,\\.h$,\\.c$,\\.cpp$,\\.java$,\\.class$,\\.py$,\\.pyc$,\\.[a-np-z]$,Makefile,Doxyfile,*,\\.info$,\\.swp$,\\.o$,\\.obj$,\\.bak$"

set backspace=2

set number
set autoindent

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

" It is now an error to run a normal mode change command over an empty region.
" See :help cpo-E for more info. I have absolutely no clue how I found this, but
" I really want it so that my custom onoremaps don't trigger changes when they
" can't find their target.
set cpo+=E

" custom mappings
nmap <C-C><C-N> :set invnumber<CR>
nnoremap <C-C><C-S> :let @/=''<CR>
" Cannot map S-F5 in terminals without fast keycode support
inoremap <F10> <C-R>=strftime("%x %X %Z")<CR>
nnoremap <F10> "=strftime("%x %X %Z")<CR>P
inoremap <S-F10> <C-R>=strftime("%b %d, %Y")<CR>
nnoremap <S-F10> "=strftime("%b %d, %Y")<CR>P
nnoremap <C-F7> :call ToggleDoxygenComments()<CR>
nnoremap <F11> :SyntasticCheck<CR>

" match indent
nnoremap =. :<C-U>exe line(".").",".(v:count1-1+line("."))."left ".string(indent(line(".")-1))<CR>

" match indent and shift
if (!GOOGLE_CORP_SPECIFIC)
  nnoremap => :<C-U>exe line(".").",".(v:count1-1+line("."))."left ".string(indent(line(".")-1)+&sw)<CR>
  nnoremap =< :<C-U>exe line(".").",".(v:count1-1+line("."))."left ".string(indent(line(".")-1)-&sw)<CR>
else
  " Hack this for google, their style is a little weird here.
  nnoremap => :<C-U>exe line(".").",".(v:count1-1+line("."))."left ".string(indent(line(".")-1)+&sw*2)<CR>
  nnoremap =< :<C-U>exe line(".").",".(v:count1-1+line("."))."left ".string(indent(line(".")-1)-&sw*2)<CR>
endif

if !RESTRICTED_MODE && has('unix')
  function! ZCM_WithClassExecute(command, classname, fnamemods)
    let l:found_file = system('global -a ' . a:classname . ' | xargs')
    let l:found_file = substitute(l:found_file, '[\x0]', '', 'g')
    if l:found_file == ''
      let l:found_file =
          \ system('ack -l "\bclass ' .  a:classname . '\b" --ignore-file=ext:html,xml')
      let l:found_file = substitute(l:found_file, '[\x0]', '', 'g')
      if l:found_file == ''
        throw 'ZCM_Vimclass: No class with name ' . a:classname . ' found'
      endif
    endif

    let l:shortform = fnamemodify(l:found_file, a:fnamemods)
    exe a:command . ' ' . l:shortform
  endfunction

  function! ZCM_Vimclass(openmode, classname)
    call ZCM_WithClassExecute(a:openmode, a:classname, ':~:.')
  endfunction

  function! ZCM_Jumpto(...)
    if len(a:000) == 0
      exe 'cd ' . expand('%:p:h')
    elseif len(a:000) == 1
      call ZCM_WithClassExecute('cd', a:classname, ':~:.:h')
    endif
  endfunction

  function! ZCM_Vimclass_Complete(ArgLead, CmdLine, CursorPos)
    let l:complete_command = "global -x '^". a:ArgLead . ".*' | sed -r -e 's/\\s.*$//g'"
    let l:found_files = system(l:complete_command)
    let l:found_files_list = split(l:found_files, '[\x0]')
    return l:found_files_list
  endfunction

  command! -nargs=1 -complete=customlist,ZCM_Vimclass_Complete Eclass call ZCM_Vimclass('e', <f-args>)
  command! -nargs=1 -complete=customlist,ZCM_Vimclass_Complete Spclass call ZCM_Vimclass('sp', <f-args>)
  command! -nargs=1 -complete=customlist,ZCM_Vimclass_Complete Vspclass call ZCM_Vimclass('vsp', <f-args>)
  command! -nargs=? -complete=customlist,ZCM_Vimclass_Complete Jumpto call ZCM_Jumpto(<f-args>)
endif

hi! link TagListFileName VisualNOS

hi! link haxeInterpolated SpecialChar
hi! link haxeInterpolatedIdent SpecialChar

"hi Pmenu ctermfg=7 ctermbg=5
"hi PmenuSel ctermfg=5 ctermbg=6

if filereadable($VIMRUNTIME . "/macros/matchit.vim")
  source $VIMRUNTIME/macros/matchit.vim
endif

" and here, if we're running at Google, we will take their changes
" (override Google stuff by putting commands after this call)
let GOOGLE_HAS_GOOGLE_VIM=0
if GOOGLE_CORP_SPECIFIC && filereadable("/usr/share/vim/google/google.vim")
  source /usr/share/vim/google/google.vim
  let GOOGLE_HAS_GOOGLE_VIM=1
endif

function IsPlugged(name)
  return has_key(g:plugs, a:name) && isdirectory(g:plugs[a:name].dir)
endfunction

call plug#begin(s:vimfiles_dir . '/plugged')

if has('nvim')
  if has('python3')
    Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
  endif
else
  if version >= 702
    " If we have Vim 7.3.885+ with Lua support, then we can actually use the
    " much faster NeoComplete instead of the older NeoComplCache.
    if has('lua') && (version == 703 && has('patch885') || version > 703)
      Plug 'Shougo/neocomplete.vim'
      " We're just going to use this startup method again, since it seems that
      " NeoComplete uses the same CursorHold load method as NeoComplCache.
      if has('autocmd')
        aug ZCM_Start_NeoComplete
        au ZCM_Start_NeoComplete VimEnter,GUIEnter *
            \ if IsPlugged('neocomplete') |
              \ NeoCompleteEnable |
              \ exe 'au! ZCM_Start_NeoComplete' |
            \ endif
        aug END
      endif
    else
      " If we're not using YCM, we might as well give NeoComplCache a shot.
      " NOTE: This option is causing the intro message to vanish after starting up.
      "let g:neocomplcache_enable_at_startup = 1
      Plug 'Shougo/neocomplcache.vim'
      " So instead of using the default startup, we'll do it ourselves here.
      if has("autocmd")
        aug ZCM_Start_NeoComplCache
        au ZCM_Start_NeoComplCache VimEnter *
            \ if IsPlugged('neocomplcache') |
              \ NeoComplCacheEnable |
              \ exe 'au! ZCM_Start_NeoComplCache' |
            \ endif
        aug END
      endif
    end
    " <TAB> completion.
    "inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
    "inoremap <expr><S-TAB>  pumvisible() ? "\<C-p>" : "\<S-TAB>"
  endif
endif

Plug 'dremelofdeath/vim-block-magic'
Plug 'gmarik/ingretu'
Plug 'tpope/vim-vividchalk'
Plug 'vim-scripts/GlobalOptions', { 'on' : ['SetBufferLocal', 'SetWindowLocal'] }

if executable('java') && (has('python') || has('python3'))
  " Plug 'artur-shaik/vim-javacomplete2', { 'for' : ['java'] }
  Plug 'dremelofdeath/vim-javacomplete2', { 'for' : ['java'] }
else
  if (!executable('java'))
    call ExplainFeature(0, 'plugin', 'vim-javacomplete2',
          \ "the 'java' binary is not executable (probably not installed)")
  endif
  if !(has('python') || has('python3'))
    call ExplainPythonFeature(0, 'plugin', 'vim-javacomplete2')
  endif
endif

if (version >= 703 && has('patch661')) || version > 703
  " These look awful on the terminal with unpatched fonts. Maybe I'll get to
  " supporting this in the future. Or something. --zack
  "Plug 'Lokaltog/powerline'
  "set rtp+=s:vimfiles_dir . "/ipi/powerline/powerline/bindings/vim
endif

if (!RESTRICTED_MODE && CheckIsCtagsExuberant())
  " taglist.vim options
  let Tlist_Compact_Format=0
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
  "Plug 'taglist.vim'
  " use taglisttoo instead now... better integration with eclim
  Plug 'ervandew/taglisttoo'
  nnoremap <F7> :TlistToo<CR>
endif

Plug 'tpope/vim-scriptease'
Plug 'tpope/vim-dispatch'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-speeddating'

Plug 'dag/vim-fish', { 'for' : ['fish'] }

if has('python') || has('python3')
  Plug 'Valloric/MatchTagAlways', { 'for' :
        \ ['jinja', 'xhtml', 'xml', 'html', 'django', 'htmldjango', 'eruby'] }
else
  call ExplainPythonFeature(0, 'plugin', 'MatchTagAlways')
endif

if GOOGLE_CORP_SPECIFIC
  let g:syntastic_check_on_open = 1

  " Extra Google-specific config opts
  let g:syntastic_java_checkers = ['glint']
  let g:syntastic_borg_checkers = ['borgcfg']
  let g:syntastic_gcl_checkers = ['gcl']
  let g:syntastic_python_checkers = ['pyflakes']
else
  let s:checkstyle_jar = s:vimfiles_dir . "/bin/checkstyle-6.0-all.jar"
  if filereadable(s:checkstyle_jar)
    let g:syntastic_java_checkers = ['checkstyle']
    let g:syntastic_java_checkstyle_classpath = s:checkstyle_jar
    let s:use_default_zack_checks = 0
    if AMAZON_CORP_SPECIFIC && has('unix')
      let s:amzn_checkstyle_ws = '/workspace/CheckstyleAntBuildLogic/src/CheckstyleAntBuildLogic'
      let s:amzn_checkfile_dir = s:amzn_checkstyle_ws . '/configuration/antfiles/config/'
      let s:amzn_checkfile = s:amzn_checkfile_dir . 'checkstyle-rules.xml'
      let s:amzn_suppressions = s:amzn_checkfile_dir . 'checkstyle-suppressions.xml'

      function! ZCM_UpdateAmazonCheckStyleDirectory()
        let g:syntastic_java_checkstyle_args = '-Dbasedir="'.getcwd().'"'
        let g:syntastic_java_checkstyle_args .= ' -Dcheckstyle.legacypackagedocs=false'
        let g:syntastic_java_checkstyle_args .= ' -Dcheckstyle.suppression.filter='
        let g:syntastic_java_checkstyle_args .= s:amzn_suppressions
        let g:syntastic_java_checkstyle_args .= ' -Dcheckstyle.linelength=100'
      endfunction

      if filereadable(s:amzn_checkfile)
        if filereadable(s:amzn_suppressions)
          let g:syntastic_check_on_open = 1
          let g:syntastic_java_checkstyle_conf_file = s:amzn_checkfile
          " Ignore missing Javadoc. Amazon's checks for this are far too noisy to be practical.
          let g:syntastic_java_checkstyle_quiet_messages =
              \ { "regex": '\v(Missing a Javadoc comment)|(Unable to get class information)' }
          call ZCM_UpdateAmazonCheckStyleDirectory()
          if has('autocmd')
            au BufEnter *.java call ZCM_UpdateAmazonCheckStyleDirectory()
          else
            echom "Autocommands are mysteriously unavailable. Without them, it will be impossible"
            echom "to automatically update your basedir property. Fix this and recompile."
          endif
        else
          echom "Amazon's CheckStyle checks are available, but the suppressions file is missing."
          echom "Using the defaults instead. Maybe the filename changed?"
          let s:use_default_zack_checks = 1
        endif
      else
      call ExplainFeature(0, 'generic', 'Amazon Checkstyle',
            \ 'the CheckstyleAntBuildLogic package is not in your workspace')
        let s:use_default_zack_checks = 1
      endif
    elseif AGILYSYS_CORP_SPECIFIC
      let g:syntastic_java_checkstyle_conf_file = s:vimfiles_dir . "/etc/agilysys_checks.xml"
    else
      let s:use_default_zack_checks = 1
    endif
    " This is the fallback for if everything else is missing for some reason.
    if s:use_default_zack_checks
      let g:syntastic_java_checkstyle_conf_file = s:vimfiles_dir . "/etc/zack_checks.xml"
    endif
  endif
endif

if has("autocmd")
  au BufNewFile,BufRead .bash{rc,_profile} let b:shell='bash'
  au BufNewFile,BufRead .zsh{rc,_profile} let b:shell='zsh'
endif

let g:syntastic_check_on_wq = 0

if !RESTRICTED_MODE
  if !AMAZON_CORP_SPECIFIC
    Plug 'scrooloose/syntastic'
  endif

  if !GOOGLE_CORP_SPECIFIC
    " Google has their own settings for this.
    Plug 'dremelofdeath/vim-highlight-extra-whitespace'
  endif
endif

if !GOOGLE_CORP_SPECIFIC && !AMAZON_CORP_SPECIFIC && !MICROSOFT_CORP_SPECIFIC
  if has('python') || has('python3')
    Plug 'jdonaldson/vaxe', { 'for' : ['haxe', 'hss', 'hxml'] }
  else
    call ExplainPythonFeature(0, 'plugin', 'vaxe')
  end

  Plug 'jeroenbourgois/vim-actionscript', { 'for' : ['actionscript'] }
endif

call plug#end()

" Glug packages...
if GOOGLE_CORP_SPECIFIC && GOOGLE_HAS_GOOGLE_VIM
  Glug blaze
  Glug g4
  Glug syntastic-google
  Glug youcompleteme-google

  " until background is fixed...
  let g:blazevim_execution = 'foreground'

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

filetype plugin indent on

" Color and window settings section
if !RESTRICTED_MODE
  if !(has("win32") || has("win64")) || has("gui_running")
    " vividchalk looks absolutely terrible in cmd.exe.
    if IsPlugged('vim-vividchalk') && (!has("unix") || $TERM != "linux")
      try
        sil colo vividchalk
      catch /^Vim\%((\a\+)\)\=:E185/
        colo elflord
      endtry
    else
      colo elflord
    endif
  else
    colo elflord
  endif
endif

set cursorline
set cursorcolumn

" Remove the underline from any cursor lines.
hi CursorLine term=NONE cterm=NONE
au ColorScheme * hi CursorLine term=NONE cterm=NONE

" window settings for gvim
" please only put GUI based settings in this section...
" stuff that doesn't require the GUI to be running should go
" in the block above this one
if has("gui_running")
  set guioptions+=c
  set guioptions-=R  " turn off the right scrollbar
  set guioptions-=L  " turn off the left scrollbar

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
    elseif AMAZON_CORP_SPECIFIC
      call BaseNotepadWindowSize(130, 1)
    else
      call NotepadWindowSize(1)
    endif
  elseif has("gui_win32")
    " screw it, on windows we just maximize
    " NOT TODAY! --zack, on Windows 7 (uncomment to enable automaximiz3e)
    " aug zcm_windows_maximize
    " au zcm_windows_maximize GUIEnter * simalt ~x
    " aug END

    " and start from our My Documents (or other home) directory if starting
    " without a filename (i.e., a new instance with a blank buffer)
    function! ChangeToHomeIfNewInstance()
      if @% == ""
        cd $USERPROFILE
      endif
    endfunction

    aug ZCM_Windows_StartFreshFromHomeDirectory
    au ZCM_Windows_StartFreshFromHomeDirectory VimEnter *
        \ sil call ChangeToHomeIfNewInstance()
    aug END

    " If we're running on the Microsoft campus, then we want to do a few extra
    " things...
    if MICROSOFT_CORP_SPECIFIC
      " Microsoft does not obey the 80 character limit, so the window should
      " really be bigger. Double ought to do it. --zack
      call NotepadWindowSize(2)
    else
      " A 100 default character limit for when we're hacking on Windows makes
      " some remote amount of sense, I think.
      call JavaNotepadWindowSize(1)
    endif
  else
    " If we don't have any idea what is going on or where we are...
    call NotepadWindowSize(1)
  endif

  " I'm pretty sure that the correct thing to do here is to check
  " companies/location first, then platforms, then companies again, but that's
  " not what's happening right now. So that's why this check is here.
  if AGILYSYS_CORP_SPECIFIC
    call JavaNotepadWindowSize(1)
  endif
else
  " Only override the mouse settings if we're not in the GUI.
  set mouse=a
endif

" End color and window settings section


" Autocommand section -- goes after bundle section since autocommands may
" depend on bundle settings
if has("autocmd")
  " Disable the audible and visual bells
  au VimEnter * set vb t_vb=
  " At some point in Vim's recent history, the above was enough to disable the
  " bells everywhere. However, now as of 7.4.711, this is no longer the case.
  " The official docs say to use GUIEnter instead of VimEnter, but to maintain
  " parity with older versions of Vim, I'm leaving the above in as well.
  au GUIEnter * set eb vb t_vb=

  " set custom syntaxes here, before syntax enable
  au BufNewFile,BufRead *.applescript set syn=applescript
  au BufNewFile,BufRead *.hx set syn=haxe
  au BufNewFile,BufRead !.tags set syn=javascript

  au BufNewFile,BufRead *.csv setlocal tw=0

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
  au BufNewFile,BufRead *.clj set ft=lisp
  au BufNewFile,BufRead *.clj setlocal lw <
  au BufNewFile,BufRead *.clj setlocal lw+=catch,def,defn,defonce,doall
  au BufNewFile,BufRead *.clj setlocal lw+=dorun,doseq,dosync,doto
  au BufNewFile,BufRead *.clj setlocal lw+=monitor-enter,monitor-exit
  au BufNewFile,BufRead *.clj setlocal lw+=ns,recur,throw,try,var
  au BufNewFile,BufRead *.clj setlocal lw+=defn-,proxy
  au BufNewFile,BufRead *.clj setlocal lw-=do
  au BufNewFile,BufRead *.clj set lisp
  aug END

  " folding options
  "set foldcolumn=3
  "set fdn=2
  "aug zcm_folding
  "au BufNewFile,BufRead *.py,_vimrc,.vimrc set foldmethod=indent
  "au BufNewFile,BufRead *.java,*.[ch],*.cpp,*.hpp set foldmethod=syntax
  "au BufNewFile,BufRead * silent! %foldo!
  "au BufNewFile,BufRead * let b:open_all_folds_bfbn=1
  "au WinEnter __Tag_List__ set foldcolumn=0
  "au Syntax java* syn region myfold start="{" end="}" transparent fold
  "au Syntax java* syn sync fromstart
  "aug END

  " I just so happen to like Doxygen-style comments, so I'm going activate them
  " by default here (but, of course, only for compatible files).
  aug zcm_doxygen
  au BufNewFile,BufRead * let b:zcm_doxified = 0
  au BufNewFile,BufRead *.[ch],*.java,*.cpp,*.hpp
      \ sil call EnableDoxygenComments()
  aug END

  " Exclude vimrc from undofile overrides since our copy is under source control
  aug zcm_vimrc_prevent_undofile_override
  au BufNewFile,BufReadPre {.,_}vimrc sil! setlocal undodir=.
  au BufNewFile,BufReadPre .bash{rc,_profile} sil! setlocal undodir=.
  au BufNewfile,BufReadPre .screenrc sil! setlocal undodir=.
  au BufNewfile,BufReadPre .tmux.conf sil! setlocal undodir=.
  au BufNewfile,BufReadPre ConEmu.xml sil! setlocal undodir=.
  au BufNewfile,BufReadPre .git{ignore,modules} sil! setlocal undodir=.
  au BufNewfile,BufReadPre situate.py sil! setlocal undodir=.
  au BufNewfile,BufReadPre situate_core.py sil! setlocal undodir=.
  au BufNewfile,BufReadPre symmap.json sil! setlocal undodir=.
  au BufNewfile,BufReadPre symmap.test.json sil! setlocal undodir=.
  aug END

  aug zcm_undofile_exclusions
  au BufNewFile,BufReadPre !.tags sil! setlocal noundofile
  aug end

  au QuickFixCmdPost,BufWinEnter,BufWinLeave *
      \ if &buftype == 'quickfix' | setlocal nonumber | endif

  " Jump to the last position in the file after opening it.
  " See :help last-position-jump for more info.
  au BufReadPost *
      \ if line("'\"") > 1 && line("'\"") <= line("$") |
          \ exe "normal! g`\"" |
      \ endif

  if GOOGLE_CORP_SPECIFIC
    if exists('*GtagOmniCompletion')
      aug ZCM_GoogleGtagsOmniCompletion
      au BufEnter * set omnifunc=GtagOmniCompletion
      aug END
    endif
    " This might be the slightest bit of a google-specific hack, but I want ,bl
    " to have nonumber set
    au FileReadPost * if &buftype == 'nofile' | setlocal nonumber | endif
    " Start a changelist description at a convenient location in piper
    aug ZCM_Google_PiperTmpDescription
    au BufReadPost .pipertmp* execute search("Description:$")+1
    aug END
  else
    au BufNewFile,BufRead *.java compiler javac
  endif

  if IsPlugged('vim-javacomplete2')
    if has('python') || has('python3')
      aug ZCM_UseJavaCompleteWhenAvailable
        au Filetype java
              \ if exists('*javacomplete#Complete') |
                \ setlocal omnifunc=javacomplete#Complete |
              \ endif
      aug END
    else
      call ExplainFeature(0, "au", "ZCM_UseJavaCompleteWhenAvailable",
            \ "neither vim feature 'python' nor 'python3' is available")
    endif
  else
    call ExplainFeature(0, "au", "ZCM_UseJavaCompleteWhenAvailable",
          \ "plugin 'vim-javacomplete2' is not plugged")
    if !has('python') && !has('python3')
      call ExplainFeature(0, "au", "ZCM_UseJavaCompleteWhenAvailable",
            \ "neither vim feature 'python' nor 'python3' is available")
    endif
  endif
endif

" End autocommand section

if !RESTRICTED_MODE
  syntax enable
endif

" If the login shell is fish, change it to something more reasonable for vim
if &shell =~# 'fish$'
  set shell=bash
endif

set report=1

set ut=10

" ts and sw need to be the same for << and >> to work correctly!
if AMAZON_CORP_SPECIFIC
  set ts=4
  set sw=4
  au BufNewFile,BufRead *.fish setlocal ts=2 | setlocal sw=2
else
  set ts=2
  set sw=2
endif

" always show the status line
set ls=2
set stl=%<%f\ #%{changenr()}
if IsPlugged('vim-fugitive')
  set stl+=\ %{fugitive#statusline()}
endif
if IsPlugged('syntastic')
  set stl+=\ %#warningmsg#%{SyntasticStatuslineFlag()}%*
endif
set stl+=\ %h%m%r%=%-14.(%l,%c%V%)\ %P

if AGILYSYS_CORP_SPECIFIC
  set tw=120
elseif AMAZON_CORP_SPECIFIC
  set tw=120
else
  if MICROSOFT_CORP_SPECIFIC != 1
    set tw=80
  endif
endif

" only use spaces instead of tabs
set expandtab

" Don't pop the preview window when using autocomplete
set completeopt-=preview

if GOOGLE_CORP_SPECIFIC
  " make sure this is just about the last line in the file, especially for corp-specific modes
  set nomodeline " this is to absolutely stop security vulnerabilities with nocompatible
endif

let g:ZM_vimrc_did_complete_load=1

" vim:ai:et:ts=2:sw=2:tw=80
