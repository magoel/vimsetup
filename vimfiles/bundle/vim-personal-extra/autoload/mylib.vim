function! mylib#InlineCommand(cmd)
    silent let l:output = system(a:cmd)
    let l:output = substitute(l:output, '[\r\n]*$', '', '')
    execute 'normal! i' . l:output
endfunction


function! mylib#Lshift(number, place)
	let l:ans = a:number
	let l:count = a:place
	while l:count > 0
		let l:ans = l:ans * 2
		let l:count = l:count - 1
	endwhile
	return l:ans
endfunction

function! mylib#Rshift(number, place)
	let l:ans = a:number
	let l:count = a:place
	while l:count > 0
		let l:ans = l:ans / 2
		let l:count = l:count - 1
	endwhile
	return l:ans
endfunction

function! mylib#OpenWindowLog(logfile)
	let l:tmpfile = tempname() " generate a temporary file name
	silent execute '!cp ' .. a:logfile .. ' ' .. l:tmpfile 
	silent execute 'vsplit'
	silent execute 'edit ' .. l:tmpfile 
	" Open the log file in a new buffer
	"execute 'edit ' .. a:logfile
	" Set the file format to unix
	setlocal fileformat=unix
	silent try | execute '%s/^##\[error\]//g' | catch /.*/  | finally | endtry
	" replace <windows drive letter>:\ with \mnt\<lowercase drive letter>\
	silent try | execute '%s/\([A-Za-z]\):\\/\\mnt\\\l\1\\/g' | catch /.*/  | finally | endtry
	" replace <windows drive letter>:/ with \mnt\<lowercase drive letter>\
	silent try | execute '%s/\([A-Za-z]\):\//\\mnt\\\l\1\\/g' | catch /.*/  | finally | endtry
	" replace \ with /
	silent try | execute '%s/\\/\//g' | catch /.*/ |  finally | endtry
	" replace /mnt/**/src/ with ./
	silent try | execute '%s/\/mnt\/\([a-z]\)\/\([a-zA-Z\/]\+\)\/src\//.\//g' | catch /.*/ | finally | endtry
	" replace /mnt/**/Import/ with ../Import/
	silent try | execute '%s/\/mnt\/\([a-z]\)\/\([a-zA-Z\/]\+\)\/Import\//..\/Import\//g' | catch /.*/ | finally | endtry
	" Write the changes to the file
	silent write
	" Close the buffer
	bdelete
	silent execute 'cfile ' .. l:tmpfile
	botright cwindow 10
endfunction



