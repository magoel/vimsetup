setlocal number "show line numbers"
setlocal wrap  " wrap lines"

setlocal foldmethod=indent "foldmethod indent"
setlocal foldlevel=2


setlocal tabstop=4
setlocal shiftwidth=4
setlocal listchars=tab:\|\ ,extends:>
setlocal list
setlocal hlsearch
setlocal incsearch
setlocal ignorecase


"mappings
nnoremap <buffer> <localleader>ev   :vertical topleft split <C-R>=<SID>ScriptPath()<cr><cr>
nnoremap <buffer> <localleader>gu   :call InlineCommand("uuidgen")<cr>

augroup CppMain
	au!
	"Remove trailing white spaces before writing files
	autocmd  BufWritePre * RemoveTrailingSpaces
augroup END



let s:filename=expand('<sfile>', ':p')
function! s:ScriptPath()
	return s:filename
endfunction
