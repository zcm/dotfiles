set nocompatible

" on Mac OS X, gets the computer name (not the host name)
function MacGetComputerName()
	let computernamestring = system("scutil --get ComputerName")
	return strpart(computernamestring, 0, strlen(computernamestring)-1)
endfunction

" these two functions allow the user to toggle between standard comments and Doxygen comments
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
		"	silent! %foldo!
		"endif
	else
		call DisableDoxygenComments()
	endif
endfunction

" window settings for gvim
if has("gui_running")
	set lines=50
	set columns=160
	colo zackvim
	if has("macunix")
		if MacGetComputerName() == "Euphoria"
			winp 351 187
		elseif MacGetComputerName() == "Bliss"
			winp 461 262
		endif
	elseif has("gui_win32")
		" screw it, on windows we just maximize
		aug zcm_windows_maximize
		au zcm_windows_maximize GUIEnter * simalt ~x
		aug END
		" also, kill win32 gvim's toolbar
		set guioptions-=T
		" and the tearoff menu items
		set guioptions-=t
		" and the standard menus themselves
		set guioptions-=m
		" and start from our My Documents (or other home) directory
		cd ~
		" set a font?
		set gfn=Lucida_Console:h10:cANSI
		" find the ctags utility
		let Tlist_Ctags_Cmd = "c:\\cygwin\\bin\\ctags.exe"
	endif
endif

" Disable the audible and visual bells
au VimEnter * set vb t_vb=

set backspace=2
syntax enable
set number
set autoindent
au BufNewFile,BufRead *.java compiler javac
filetype on
filetype indent on

" folding options
set foldcolumn=3
set fdn=2
aug zcm_folding
au zcm_folding BufNewFile,BufRead *.py,_vimrc,.vimrc set foldmethod=indent
au zcm_folding BufNewFile,BufRead *.java,*.[ch],*.cpp,*.hpp set foldmethod=syntax
au zcm_folding BufNewFile,BufRead * silent! %foldo!
au zcm_folding BufNewFile,BufRead * let b:open_all_folds_bfbn=1
au zcm_folding WinEnter __Tag_List__ set foldcolumn=0
au zcm_folding Syntax java* syn region myfold start="{" end="}" transparent fold
au zcm_folding Syntax java* syn sync fromstart
aug END

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

" always show the status line
" set laststatus=2

