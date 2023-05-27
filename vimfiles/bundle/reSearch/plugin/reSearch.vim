if exists("loaded_reSearch")
    finish
endif

setlocal switchbuf=uselast
"research mappings
"rd -- reSearch definition
nnoremap  <localleader>rd :call <SID>ReSearchCli('<C-R>=expand("<cword>")<CR>', 1)<CR>
"rr -- reSearch references
nnoremap  <localleader>rr :call <SID>ReSearchCli('<C-R>=expand("<cword>")<CR>', 2)<CR>
"rc -- reSearch cursor
nnoremap  <localleader>rc :call <SID>ReSearchCli('<C-R>=expand("<cword>")<CR>', 3)<CR>
"re -- reSearch expression -- will prompt user
nnoremap  <localleader>re :call <SID>ReSearchCli('', 4)<CR>
"rs -- ask user to change reSearch scope
nnoremap  <localleader>rs :call <SID>ChangeReSearchScope()<CR>
"rs -- ask user to change reSearch size limit
nnoremap  <localleader>rl :call <SID>ChangeReSearchSizeLimit()<CR>


let s:reSearchCliCmd = "node /mnt/c/Users/mgoel/repos/mgoel/codeSearch/index.js"
if exists("g:reSearchCliCmd")
	let s:reSearchCliCmd = g:reSearchCliCmd
endif

let s:reSearchScope = "/word"
if exists("g:reSearchScope")
	let s:reSearchScope = g:reSearchScope
endif

let s:reSearchResultSizeLimit = 50
if exists("g:reSearchResultSizeLimit")
	let s:reSearchResultSizeLimit = g:reSearchResultSizeLimit
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
				\ ' --top ' .. s:reSearchResultSizeLimit .. 
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

function! s:ChangeReSearchSizeLimit()
	call inputsave()
	" todo provide command completion here
	let l:resultSizeLimit = input("ReSearch result size limit: ", s:reSearchResultSizeLimit)
	call inputrestore()
	let l:resultSizeLimit = trim(l:resultSizeLimit)
	if l:resultSizeLimit =~# '^$'
		echom 'Blank reSearch resultSizeLimit .. restoring previous'
	elseif l:resultSizeLimit !~# '[0-9]\+'
		echom 'resultSizeLimit should be integer value'
	else
		let s:reSearchResultSizeLimit = +l:resultSizeLimit
	endif
endfunction

let s:filename=expand('<sfile>', ':p')
function! s:ScriptPath()
	return s:filename
endfunction
let loaded_reSearch = 1
