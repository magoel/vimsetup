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
GtagsCscope


"mappings

"edit vimrc for this filetype
nnoremap <buffer> <localleader>ev   :vertical topleft split <C-R>=<SID>ScriptPath()<cr><cr>
"source vimrc for this filetype
nnoremap <buffer> <localleader>sv   :source <C-R>=<SID>ScriptPath()<cr><cr>
"generate uuid
nnoremap <buffer> <localleader>uid   :call mylib#InlineCommand("uuidgen")<cr>

"Lookup gtags at current cursor contextually
nnoremap <buffer> <localleader>gr :GtagsCursor<cr>:cc<cr>
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
nnoremap <buffer> <localleader>cf :call <SID>ClangFormat()<cr>
"Start Lsp Server
nnoremap <buffer> <localleader>ls :call <SID>StartLspServerForCpp()<cr>

"research mappings
"rd -- reSearch definition
nnoremap <buffer> <localleader>rd :call <SID>ReSearchCli('<C-R>=expand("<cword>")<CR>', 1)<CR>
"rr -- reSearch references
nnoremap <buffer> <localleader>rr :call <SID>ReSearchCli('<C-R>=expand("<cword>")<CR>', 2)<CR>
"rc -- reSearch cursor
nnoremap <buffer> <localleader>rc :call <SID>ReSearchCli('<C-R>=expand("<cword>")<CR>', 3)<CR>
"re -- reSearch expression -- will prompt user
nnoremap <buffer> <localleader>re :call <SID>ReSearchCli('', 4)<CR>
"rs -- ask user to change reSearch scope
nnoremap <buffer> <localleader>rs :call <SID>ChangeReSearchScope()<CR>


let s:reSearchCliCmd = "node /mnt/c/Users/mgoel/repos/mgoel/codeSearch/index.js"
if exists("g:reSearchCliCmd")
	let s:reSearchCliCmd = g:reSearchCliCmd
endif

let s:reSearchScope = "/word"
if exists("g:reSearchScope")
	let s:reSearchScope = g:reSearchScope
endif


let s:reSearchCacheDir = getcwd(-1) .. "/reSearchCache"
if exists("g:reSearchCacheDir")
	let s:reSearchCacheDir  = g:reSearchCacheDir
endif

let s:reSearchDefinition = 1
let s:reSearchReference = 2
let s:reSearchCursor = 3
let s:reSearchExpression=4

function! s:ReSearchCli(searchexpr, kind)
	let l:searchexpr = trim(a:searchexpr)
	let l:kind = a:kind
	if l:searchexpr =~# '^$'
		" searchexpr is empty
		let l:kind = 4
		"todo : add custom completion using global as well
		call inputsave()
		let l:searchexpr = input("ReSearch pattern: ", expand('<cword>'))
		call inputrestore()
		let l:searchexpr = trim(l:searchexpr)
		" still empty
		if l:searchexpr =~# '^$'
			echom "Blank search-epxression found .. terminating search"
			return
		endif
		echom ""
	endif
	let l:cmd = s:reSearchCliCmd .. ' '
	if l:kind == s:reSearchDefinition
		let l:cmd = l:cmd .. shellescape('def:' .. l:searchexpr)
	elseif l:kind == s:reSearchReference
		let l:cmd = l:cmd .. shellescape('ref:' .. l:searchexpr)
	else
		" both cursor and expression are plugged as is
		let l:cmd = l:cmd .. shellescape(l:searchexpr)
	endif
	let l:cmd = l:cmd ..
				\ ' --scope ' .. s:reSearchScope .. 
				\ ' --cachedir ' .. s:reSearchCacheDir .. 
				\ '  --download '
	echom 'Executing : ' .. l:cmd
	let l:qfixtitle = 'searchExpr : ' .. l:searchexpr .. '  in scope of ' .. s:reSearchScope
	let l:result = systemlist(l:cmd)
	if len(l:result) == 0 
		echom "Failed to search " .. l:searchexpr .. " in scope of " .. s:reSearchScope
		if len(s:reSearchScope) > 1
			"save current scope
			let l:saveReSearchScope = s:reSearchScope
			" go a level up in reSearchScope
			let s:reSearchScope = fnamemodify(s:reSearchScope, ":h")
			echom "Trying search " .. l:searchexpr .. " in scope of " .. s:reSearchScope
			call <SID>ReSearchCli(l:searchexpr, 3)
			" restore scope
			let s:reSearchScope = l:saveReSearchScope
		endif
	else
		call setqflist([], ' ', {'lines' : l:result, 'title' : l:qfixtitle})
		" open quickfix window of height 10 at bottom
		botright cwindow 10
	endif
endfunction

function! s:ChangeReSearchScope()
	call inputsave()
	" todo provide command completion here
	let l:scope = input("ReSearch Scope: ", s:reSearchScope)
	call inputrestore()
	let l:scope = trim(l:scope)
	if l:scope =~# '^$'
		echom 'Blank reSearch scope .. restoring previous'
	elseif l:scope !~# '^\/.*'
		echom 'Scope has to start with /'
	else
		let s:reSearchScope = l:scope
	endif
endfunction

let s:filename=expand('<sfile>', ':p')
function! s:ScriptPath()
	return s:filename
endfunction


if exists("g:clangFormatPythonScriptPath")
    let s:clangFormatPythonScriptPath = g:clangFormatPythonScriptPath
else
	let s:clangFormatPythonScriptPath = findfile("~/localInstall/clang-format.py")
endif

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



" helper files
" movement.vim
" header.vim
