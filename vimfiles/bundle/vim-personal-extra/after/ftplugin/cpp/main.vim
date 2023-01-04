setlocal number "show line numbers"
setlocal wrap  " wrap lines"

setlocal foldmethod=syntax
setlocal foldlevel=2


setlocal tabstop=4
setlocal shiftwidth=4
setlocal listchars=tab:\|\ ,extends:>
setlocal list
setlocal hlsearch
setlocal incsearch
setlocal ignorecase


"configure gtags
setlocal cscopetag
setlocal switchbuf=useopen
let GtagsCscope_Ignore_Case = 1
let GtagsCscope_Keep_Alive = 1
let g:Gtags_No_Auto_Jump = 0
let GtagsCscope_Auto_Map = 0

" if executable('ctags-exuberant')
" 	" On Debian Linux, exuberant ctags is installed
" 	" as exuberant-ctags
" 	let Tlist_Ctags_Cmd = 'ctags-exuberant'
" endif

"Load Gtags db
GtagsCscope


"mappings
nnoremap <buffer> <localleader>ev   :vertical topleft split <C-R>=<SID>ScriptPath()<cr><cr>
nnoremap <buffer> <localleader>sv   :source <C-R>=<SID>ScriptPath()<cr><cr>
nnoremap <buffer> <localleader>uid   :call mylib#InlineCommand("uuidgen")<cr>

nnoremap <buffer> <localleader>gr :GtagsCursor<cr>:cc<cr>
nnoremap <buffer> <localleader>cs :cs find s <C-R>=expand("<cword>")<CR><CR>
nnoremap <buffer> <localleader>cg :cs find g <C-R>=expand("<cword>")<CR><CR>
nnoremap <buffer> <localleader>cc :cs find c <C-R>=expand("<cword>")<CR><CR>
nnoremap <buffer> <localleader>ct :cs find t <C-R>=expand("<cword>")<CR><CR>
nnoremap <buffer> <localleader>ce :cs find e <C-R>=expand("<cword>")<CR><CR>
nnoremap <buffer> <localleader>cf :cs find f <C-R>=expand("<cfile>")<CR><CR>
nnoremap <buffer> <localleader>ci :cs find i <C-R>=expand("<cfile>")<CR><CR>
nnoremap <buffer> <localleader>o  :Gtags -Pi  
nnoremap <buffer> <localleader>d  :Gtags -di  
nnoremap <buffer> <localleader>s :Gtags -f %<cr>


augroup CppMain
	au!
	"Remove trailing white spaces before writing files
	autocmd  BufWritePre <buffer> RemoveTrailingSpaces
augroup END


let s:filename=expand('<sfile>', ':p')
function! s:ScriptPath()
	return s:filename
endfunction
