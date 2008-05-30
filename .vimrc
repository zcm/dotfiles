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
	else
		call DisableDoxygenComments()
	endif
endfunction

" I just so happen to like Doxygen-style comments, so I'm going activate them by default here
" (but, of course, only for compatible files with an autocommand)
aug zcm_doxygen
au zcm_doxygen BufEnter * let b:zcm_doxified = 0
au zcm_doxygen BufEnter *.[ch],*.java,*.cpp,*.hpp call EnableDoxygenComments()
aug END

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
	endif
endif

" Disable the audible and visual bells
au VimEnter * set vb t_vb=

set backspace=2
syntax enable
set number
set autoindent
autocmd BufNewFile,BufRead *.java compiler javac

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
nnoremap <F6> :call ToggleDoxygenComments()<CR>

" always show the status line
" set laststatus=2

