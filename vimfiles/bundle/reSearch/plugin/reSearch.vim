if exists("loaded_reSearch")
    finish
endif

let s:filename=expand('<sfile>', ':p')
function! s:ScriptPath()
	return s:filename
endfunction
let s:curFileDir = fnamemodify(s:ScriptPath(),":p:h")

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
"rl -- ask user to change reSearch size limit
nnoremap  <localleader>rl :call <SID>ChangeReSearchSizeLimit()<CR>
"rp -- ask user to change reSearch project name
nnoremap  <localleader>rp :call <SID>ChangeReSearchProjectName()<CR>
"ro -- ask user to change reSearch repo name
nnoremap  <localleader>ro :call <SID>ChangeReSearchRepository()<CR>
"rb -- ask user to change reSearch branch name
nnoremap  <localleader>rb :call <SID>ChangeReSearchBranch()<CR>


" check if executable node is defined on system path or its paths is given in g:NodePath
function! s:EvalNodePath()
	if exists("g:NodePath")
		let l:nodePath = g:NodePath
		if !filereadable(l:nodePath)
			echom "node is not found at given path " .. l:nodePath
			echom "Please install node and make sure it is available on system path or at given path"
		endif
		return l:nodePath
	else
		if !executable("node")
			echom "node is not found on system path"
			echom "Please install node and make sure it is available on system path or at given path"
		endif
		return "node"
	endif
endfunction

function! s:EvalResearchAppDir()
	if exists("g:reSearchAppDir")
		let l:reSearchAppDir = g:reSearchAppDir
		" check if it is a directory and exists
		if !isdirectory(l:reSearchAppDir)
			echom "reSearchAppDir is not a directory or does not exists " .. l:reSearchAppDir
			echom "Please install reSearch and make sure it is available on system path or at given path"
		endif
		return l:reSearchAppDir
	else
		" check in parent path of current file directory
		let l:reSearchAppDir = finddir('codeSearch', s:curFileDir . ';')
		" check if l:reSearchAppDir is empty
		if l:reSearchAppDir ==# ''
			echom "reSearchAppDir is not found in current directory or its parent"
			echom "Please install reSearch and make sure it is available on system path or at given path"
		endif
		return l:reSearchAppDir
	endif
endfunction

function! s:EnsureReSearchAppDirDependency()
	let l:reSearchAppDir = s:EvalResearchAppDir()
	if !isdirectory(l:reSearchAppDir .. '/node_modules')
		let l:cwd = getcwd()
		execute 'cd ' .. l:reSearchAppDir
		let l:cmd = 'npm install'
		call system(l:cmd)
		" check if npm install was successful
		if v:shell_error
			echom "npm install failed at " .. l:reSearchAppDir
			execute 'cd ' .. l:cwd
		endif
		execute 'cd ' .. l:cwd
	endif
endfunction


function! s:EvalReSearchCliCmd()
	if exists("g:reSearchCliCmd")
		return g:reSearchCliCmd
	else
		let l:NodePath = s:EvalNodePath()
		let l:reSearchAppDir = s:EvalResearchAppDir()
		call s:EnsureReSearchAppDirDependency()
		return l:NodePath .. ' ' .. l:reSearchAppDir .. '/index.js'
	endif
endfunction

let s:reSearchCliCmd = s:EvalReSearchCliCmd()

let s:reSearchScope = "/word"
if exists("g:reSearchScope")
	let s:reSearchScope = g:reSearchScope
endif

let s:reSearchResultSizeLimit = 50
if exists("g:reSearchResultSizeLimit")
	let s:reSearchResultSizeLimit = g:reSearchResultSizeLimit
endif

let s:reSearchProjectName = "office"
if exists("g:reSearchProjectName")
	let s:reSearchProjectName = g:reSearchProjectName
endif

let s:reSearchRepoName = "office"
if exists("g:reSearchRepoName")
	let s:reSearchRepoName = g:reSearchRepoName
endif

let s:reSearchBranchName = "main"
if exists("g:reSearchBranchName")
	let s:reSearchBranchName = g:reSearchBranchName
endif


let s:reSearchCacheDir = getcwd(-1) .. "/reSearchCacheDir"
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
				\ ' --project ' .. s:reSearchProjectName .. 
				\ ' --repository ' .. s:reSearchRepoName .. 
				\ ' --branch ' .. s:reSearchBranchName .. 
				\ ' --cachedir ' .. s:reSearchCacheDir .. 
				\ ' --download '
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

function! s:ChangeReSearchProjectName()
	call inputsave()
	" todo provide command completion here
	let l:projectName = input("ReSearch Project: ", s:reSearchProjectName)
	call inputrestore()
	let l:projectName = trim(l:projectName)
	if l:projectName =~# '^$'
		echom 'Blank reSearch projectName .. restoring previous'
	else
		let s:reSearchProjectName = l:projectName
	endif
endfunction

function! s:ChangeReSearchBranch()
	call inputsave()
	" todo provide command completion here
	let l:branchName = input("ReSearch BranchName: ", s:reSearchBranchName)
	call inputrestore()
	let l:branchName = trim(l:branchName)
	if l:branchName =~# '^$'
		echom 'Blank reSearch branchName .. restoring previous'
	else
		let s:reSearchBranchName = l:branchName
	endif
endfunction

function! s:ChangeReSearchRepository()
	call inputsave()
	" todo provide command completion here
	let l:repoName = input("ReSearch Repository: ", s:reSearchRepoName)
	call inputrestore()
	let l:repoName = trim(l:repoName)
	if l:repoName =~# '^$'
		echom 'Blank reSearch repoName .. restoring previous'
	else
		let s:reSearchRepoName = l:repoName
	endif
endfunction

function! s:EvalPullRequestCliCmd()
	if exists("g:pullRequestCliCmd")
		return g:pullRequestCliCmd
	else
		let l:NodePath = s:EvalNodePath()
		let l:reSearchAppDir = s:EvalResearchAppDir()
		call s:EnsureReSearchAppDirDependency()
		" join path in platform independent way
		return l:NodePath .. ' ' .. l:reSearchAppDir .. '/ado.js'
	endif
endfunction

let s:pullRequestCliCmd = s:EvalPullRequestCliCmd()

function! s:GetPrComments(prId)
	let l:prId = a:prId
	if l:prId =~# '^$'
		" prId is empty
		call inputsave()
		let l:prId = input("PR Id: ", expand('<cword>'))
		call inputrestore()
		let l:prId = trim(l:prId)
		" still empty
		if l:prId =~# '^$'
			echom "Blank prId found .. terminating search"
			return
		endif
	endif
	let l:cmd = s:pullRequestCliCmd .. 
				\ ' downloadpr ' ..
				\ ' --project ' .. s:reSearchProjectName .. 
				\ ' --repository ' .. s:reSearchRepoName ..
				\ ' --pullRequestId ' .. l:prId ..
				\ ' --status all'
	echom 'Executing : ' .. l:cmd
	let l:qfixtitle = 'PR Comments for ' .. 
				\ s:reSearchProjectName .. '/' ..
				\ s:reSearchRepoName .. '/' ..
				\ l:prId
	let l:result = systemlist(l:cmd)
	if len(l:result) == 0 
		echom "Failed to get comments for PR " .. l:prId
	else
		call setqflist([], ' ', {'lines' : l:result, 'title' : l:qfixtitle})
		" open quickfix window of height 10 at bottom
		botright cwindow 10
	endif
endfunction
" define a command which excepts a numeric argument and calls GetPrComments
command! -nargs=1 PRComments call s:GetPrComments(<f-args>)

function! s:ListPRsSink(lines)
	let l:prId = matchlist(a:lines, '^\(\d\+\):')[1]
	let l:prId = str2nr(l:prId)
	call s:GetPrComments(l:prId)
endfunction


function! s:ListPRs()
	if !exists('*fzf#wrap')
		echom "fzf.vim is not available"
		return
	endif
	let l:cmd = s:pullRequestCliCmd .. 
				\ ' listpr ' ..
				\ ' --project ' .. s:reSearchProjectName .. 
				\ ' --repository ' .. s:reSearchRepoName ..
				\ ' --status active'
	let opts = fzf#wrap({
				\ 'source':  l:cmd,
				\ 'sink*':   function('s:ListPRsSink'),
				\ 'options' : ['--prompt', 'PRs> ', '--ansi', '+m', '-x', '--tiebreak=index']
				\ })
	call fzf#run(opts)
endfunction
" define a command which calls ListPRs
command! Pullrequests call s:ListPRs()



function! s:ListGtagsSink(lines)
	" check if :Gtags command is available
	if !exists(':Gtags')
		echom "Gtags command is not available"
		return
	endif
	" check length of lines
	if len(a:lines) == 0
		echom "No lines selected"
		return
	endif
	" let buf = bufnr()
	" let view = winsaveview()
	call setqflist([], 'r')
	for l:line in a:lines
		execute('Gtagsa -qde ' .. l:line)
		execute('Gtagsa -qre ' .. l:line)
	endfor
    " call execute('b '.buf)
    " call winrestview(view)
endfunction


let s:global_command = $GTAGSGLOBAL
if s:global_command == ''
        let s:global_command = "global"
endif
function! s:ListGtags(...)
	let l:searchexpr = ''
	" check if first argument is present and of type string
	" if yes, assign it to searchexpr
	if len(a:000) > 0 && type(a:000[0]) == type('')
		let l:searchexpr = trim(a:000[0])
	endif
	if !exists('*fzf#wrap')
		echom "fzf.vim is not available"
		return
	endif
	if !exists(':Gtags')
		echom "Gtags command is not available"
		return
	endif
	if !executable(s:global_command)
		echom s:global_command .. " is not available"
		return
	endif
	let l:cmd = 'global -c '
	let opts = fzf#wrap({
				\ 'source':  l:cmd,
				\ 'sink*':   function('s:ListGtagsSink'),
				\ 'options' : ['--prompt', 'GTags> ', '--ansi', '+m', '-x', '--tiebreak=index', '--preview',
				\	'(global --result=ctags-mod -qde {};global --result=ctags-mod -qre {}) | sed "s/[[:blank:]]/:/;s/[[:blank:]]/:/" | batcat - --color always -l cpp --theme TwoDark',
				\   '--preview-window', 'right:65%',
				\   '--query', l:searchexpr]
				\ })
	call fzf#run(opts)
endfunction
nnoremap  <localleader>gt :call <SID>ListGtags('<C-R>=expand("<cword>")<CR>')<CR>


let loaded_reSearch = 1
