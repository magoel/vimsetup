  " Move around functions.
  nnoremap <silent><buffer> [[ m':call search('\v(^\{)', "bW")<CR>
  vnoremap <silent><buffer> [[ m':<C-U>exe "normal! gv"<Bar>call search('\v(^\{)', "bW")<CR>
  nnoremap <silent><buffer> ]] m':call search('\v(^\{)', "W")<CR>
  vnoremap <silent><buffer> ]] m':<C-U>exe "normal! gv"<Bar>call search('\v(^\{)', "W")<CR>
  nnoremap <silent><buffer> [] m':call search('\v(^\s*\{)', "bW")<CR>
  vnoremap <silent><buffer> [] m':<C-U>exe "normal! gv"<Bar>call search('\v(^\s*\{)', "bW")<CR>
  nnoremap <silent><buffer> ][ m':call search('\v(^\s*\{)', "W")<CR>
  vnoremap <silent><buffer> ][ m':<C-U>exe "normal! gv"<Bar>call search('\v(^\s*\{)', "W")<CR>
