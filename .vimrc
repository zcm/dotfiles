set nocompatible

" on Mac OS X, gets the computer name (not the host name)
function MacGetComputerName()
	let computernamestring = system("scutil --get ComputerName")
	return strpart(computernamestring, 0, strlen(computernamestring)-1)
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
	endif
endif

" Disable the audible and visual bells
set vb t_vb=

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

" always show the status line
" set laststatus=2

