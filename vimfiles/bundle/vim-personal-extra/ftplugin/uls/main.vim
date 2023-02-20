setlocal number "show line numbers"
setlocal nowrap  " wrap lines"

setlocal tabstop=4
setlocal shiftwidth=4
setlocal nolist
setlocal hlsearch
setlocal incsearch
setlocal ignorecase

"set foldmethod to expression .... based on co-relation vector


"mappings
nnoremap <buffer> <localleader>ev   :vertical topleft split <C-R>=<SID>ScriptPath()<cr><cr>
nnoremap <buffer> <localleader>sv   :source <C-R>=<SID>ScriptPath()<cr><cr>
nnoremap <buffer> <localleader>ct   :call <SID>ConvertToTagString()<cr>
nnoremap <buffer> <localleader>ch   :call <SID>ConvertToHex()<cr>
" nnoremap <buffer> <localleader>cd   :call <SID>ConvertToDecimal()<cr>

augroup CppMain
	au!
	" run tag conversion
	"autocmd  BufWritePre * RemoveTrailingSpaces
augroup END



let s:filename=expand('<sfile>', ':p')
function! s:ScriptPath()
	return s:filename
endfunction


function! s:ConvertToHex()
	"appends converted tag value inside brackets
	" expected to be used inside normal mode
	let l:number = expand("<cWORD>") + 0
	"let l:output = sha256(l:number)
	let l:output = printf("%x", l:number)
    execute 'normal! ea(' . l:output . ')'
	" also add the tag to system clipboard register
	let @+ = l:output
endfunction

function! s:ConvertToTagString()
	"appends converted tag value inside brackets
	" expected to be used inside normal mode
	let l:number = expand("<cword>") + 0
	"let l:output = sha256(l:number)
	let l:output = s:TagToString(l:number)
    execute 'normal! ea(' . l:output . ')'
	" also add the tag to system clipboard register
	let @+ = l:output
endfunction

function! s:ConvertTagToStringSymbol(number)
	return strpart('abcdefghijklmnopqrstuvwxyz0123456789****************************',a:number, 1)
endfunction


function! s:AsciiTable(number)
	if a:number >= 32 && a:number <= 126
		return strpart(" !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz", a:number - 32, 1)
	else
		return " "
	endif
endfunction

function! s:TagToString(number)
	let l:number = a:number + 0
	if l:number < 0xffff
		return "tag_" . l:number
	else
		if mylib#Rshift(l:number, 24) >= 36
			let l:ans = ""
			let l:ans .= s:AsciiTable(and(mylib#Rshift(l:number, 24), 0xff))
			let l:ans .= s:AsciiTable(and(mylib#Rshift(l:number, 16), 0xff))
			let l:ans .= s:AsciiTable(and(mylib#Rshift(l:number, 8), 0xff))
			let l:ans .= s:AsciiTable(and(mylib#Rshift(l:number, 0), 0xff))
			return "tag_" . l:ans
		else
			let l:ans = ""
			let l:ans .= s:ConvertTagToStringSymbol(and(mylib#Rshift(l:number, 24), 0x3f))
			let l:ans .= s:ConvertTagToStringSymbol(and(mylib#Rshift(l:number, 18), 0x3f))
			let l:ans .= s:ConvertTagToStringSymbol(and(mylib#Rshift(l:number, 12), 0x3f))
			let l:ans .= s:ConvertTagToStringSymbol(and(mylib#Rshift(l:number, 6), 0x3f))
			let l:ans .= s:ConvertTagToStringSymbol(and(mylib#Rshift(l:number, 0), 0x3f))
			return "tag_" . l:ans
		endif
	endif
endfunction
