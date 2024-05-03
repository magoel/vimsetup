let s:filename=expand('<sfile>', ':p')
function! s:ScriptPath()
	return s:filename
endfunction
let s:curFileDir = fnamemodify(s:ScriptPath(),":p:h")


setlocal number "show line numbers"
setlocal wrap  " wrap lines"

"setlocal foldmethod=syntax
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
setlocal switchbuf=uselast
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
"GtagsCscope


"mappings

"edit vimrc for this filetype
nnoremap <buffer> <localleader>ev   :vertical topleft split <C-R>=<SID>ScriptPath()<cr><cr>
"source vimrc for this filetype
nnoremap <buffer> <localleader>sv   :source <C-R>=<SID>ScriptPath()<cr><cr>
"generate uuid
nnoremap <buffer> <localleader>uid   :call mylib#InlineCommand("uuidgen")<cr>


"Lookup gtags at current cursor contextually
nnoremap <buffer> <localleader>gr :call <SID>LookupGtags('<C-R>=expand("<cword>")<CR>')<cr>
nnoremap <buffer> <localleader>gf :Gtags -Pi <C-R>=expand("<cword>")<CR><cr>
"cscope symbol
nnoremap <buffer> <localleader>cs :cs find s <C-R>=expand("<cword>")<CR><CR>
"cscope definition
nnoremap <buffer> <localleader>cg :cs find g <C-R>=expand("<cword>")<CR><CR>
"cscpoe callers
nnoremap <buffer> <localleader>cc :cs find c <C-R>=expand("<cword>")<CR><CR>
"cscope text
nnoremap <buffer> <localleader>ct :cs find t <C-R>=expand("<cword>")<CR><CR>
"cscope egrep
nnoremap <buffer> <localleader>ce :cs find e <C-R>=expand("<cword>")<CR><CR>
"cscope file
nnoremap <buffer> <localleader>cf :cs find f <C-R>=expand("<cfile>")<CR><CR>
" cscope include file search
nnoremap <buffer> <localleader>ci :cs find i <C-R>=expand("<cfile>")<CR><CR>
" open file
nnoremap <buffer> <localleader>o  :Gtags -Pi<cr>
" goto def
nnoremap <buffer> <localleader>d  :Gtags -di<cr>
"summarise file
nnoremap <buffer> <localleader>s :Gtags -f %<cr>
"clang format
noremap <buffer> <localleader>= :call <SID>ClangFormat()<cr>
"Start Lsp Server
nnoremap <buffer> <localleader>ls :call <SID>StartLspServerForCpp()<cr>

"create a map to do following
"search 0x to left of cursor
"then search 2nd / character to right of cursor
"then select the text between these two points
"and replace it with UNTAGGED
nnoremap <buffer> <localleader>ut w?0x<cr>c2f/UNTAGGED<esc>
" nnoremap <buffer> <localleader>ut :call search('0x', 'b')<cr>:call search('/', 'w')<cr>viw:s/0x.*\//UNTAGGED/<cr>


function! s:EvalClangFormatScriptPath()
	if exists("g:clangFormatPythonScriptPath")
		let l:clangFormatPythonScriptPath = g:clangFormatPythonScriptPath
		" check if the file exists
		if !filereadable(l:clangFormatPythonScriptPath)
			echom l:clangFormatPythonScriptPath .. " is not a valid file"
			return ""
		endif
		return l:clangFormatPythonScriptPath
	else
		let l:clangFormatPythonScriptPath = findfile("clang-format.py", s:curFileDir . ";")
		if l:clangFormatPythonScriptPath ==# ""
			echom "clang-format.py not found"
			return ""
		endif
		return l:clangFormatPythonScriptPath
	endif
endfunction

let s:clangFormatPythonScriptPath = s:EvalClangFormatScriptPath()

function! s:ClangFormat()
	if s:clangFormatPythonScriptPath !=# ""
		execute "py3file " . s:clangFormatPythonScriptPath
	endif
endfunction

function! s:Formatonsave()
	if s:clangFormatPythonScriptPath !=# ""
		let l:formatdiff = 1
		execute "py3file " . s:clangFormatPythonScriptPath
	endif
endfunction

function! s:StartLspServerForCpp()
	"configuring lsp
	echom "Starting Lsp Server for CppMain"
	if executable("clangd")
		let lspServers = [
					\     #{
					\        filetype: ['c', 'cpp'],
					\        path: 'clangd',
					\        args: ['--background-index']
					\      }
			\   ]

		call LspAddServer(lspServers)
		let lspOpts = {'autoHighlightDiags': v:false}
		augroup CppLsp
			au!
			autocmd VimEnter * call LspAddServer(lspServers)
			autocmd VimEnter * call LspOptionsSet(lspOpts)
		augroup END
	endif
endfunction

function! s:LookupGtags(searchExpr)
	" check if :Gtags command is available
	if !exists(':Gtags')
		echom "Gtags command is not available"
		return
	endif
	" check if the search expression is empty
	let l:searchExpr = trim(a:searchExpr)
	if l:searchExpr ==# ""
		echom "Search expression is empty"
		return
	endif
	call setqflist([], 'r')
	execute('Gtagsa -qde ' .. l:searchExpr)
	execute('Gtagsa -qre ' .. l:searchExpr)
	call setqflist([], 'a', {'title' : 'Gtags ' .. l:searchExpr})
endfunction


" helper files
" movement.vim
" header.vim
