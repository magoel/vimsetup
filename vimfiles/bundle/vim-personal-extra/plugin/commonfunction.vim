function! InlineCommand(cmd)
    silent let l:output = system(a:cmd)
    let l:output = substitute(l:output, '[\r\n]*$', '', '')
    execute 'normal! i' . l:output
endfunction
