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

