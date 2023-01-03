"define visual mapping to add function/class-header


let g:CppHeaderAuthorName =  "magoel"

vnoremap <buffer> <localleader>ch :<c-u>call <SID>GenHeader("Class", "")<cr>
vnoremap <buffer> <localleader>fh :<c-u>call <SID>GenHeader("Function", "")<cr>

function! s:GenHeader(construct, name)
	" only allow char-wise visual mode
	if visualmode() !=# 'v'
		return
	endif

	let l:saved_unnamed_register = @@
	normal! `<v`>y
	let l:line = line("'<") - 1 "line above selected
	let l:header = []
	let l:header += ["/*-----------------------------------------------------------------------------"]
	let l:header += ["	%%" . a:construct . ": " . @@]
	let l:header += ["	%%Author: " . g:CppHeaderAuthorName]
	let l:header += ["-----------------------------------------------------------------------------*/"]
	call append(l:line, l:header)
	let @@ = l:saved_unnamed_register
endfunction


function! s:GenFileHeader()
	if nextnonblank(1) != 0
		"skip if file is not empty
		return
	endif

	let l:header = []
	let l:header += ["/*-----------------------------------------------------------------------------"]
	let l:header += ["	%%File: " . expand("<afile>", ":p:t")]
	let l:header += ["-----------------------------------------------------------------------------*/"]
	call append(0, l:header)
endfunction


augroup CppHeader
	au!
	au BufWritePre <buffer> :call <SID>GenFileHeader()
augroup END
