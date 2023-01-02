setlocal number "show line numbers"
setlocal wrap  " wrap lines"

setlocal foldmethod=indent "foldmethod indent"
setlocal foldlevel=2


setlocal tabstop=4
setlocal shiftwidth=4
setlocal listchars=tab:\|\  
setlocal list
setlocal hlsearch
setlocal incsearch
setlocal ignorecase

augroup CppMain
	au!
	"Remove trailing white spaces before writing files
	autocmd  BufWritePre * RemoveTrailingSpaces
augroup END
