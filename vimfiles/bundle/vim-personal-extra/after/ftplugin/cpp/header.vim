"define visual mapping to add function/class-header


let g:CppHeaderAuthorName =  "magoel"

vnoremap <buffer> <localleader>ch :<c-u>call <SID>GenHeader("Class", "")<cr>
vnoremap <buffer> <localleader>fh :<c-u>call <SID>GenHeader("Function", "")<cr>
nnoremap <buffer> <localleader>ch :<c-u>call <SID>GenHeader("Class", expand("<cword>"))<cr>
nnoremap <buffer> <localleader>fh :<c-u>call <SID>GenHeader("Function", expand("<cword>"))<cr>

function! s:GenHeader(construct, name)
	" only allow char-wise visual mode
	let l:saved_unnamed_register = @@
	if  a:name ==# ""
		normal! `<v`>y
		let l:fname = @@
		let l:line = line("'<") - 1 "line above selected
	else
		let l:fname = a:name
		let l:line = line(".") - 1 "line above selected
	endif
	let l:header = []
	let l:header += ["/*-----------------------------------------------------------------------------"]
	let l:header += ["	%%" . a:construct . ": " . l:fname]
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
