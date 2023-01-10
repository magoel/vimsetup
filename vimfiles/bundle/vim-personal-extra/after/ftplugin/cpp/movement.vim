
noremap <script> <buffer> <silent> ]]
        \ :call <SID>NextSection(1, 0, 0)<cr>

noremap <script> <buffer> <silent> [[
        \ :call <SID>NextSection(1, 1, 0)<cr>

noremap <script> <buffer> <silent> ][
        \ :call <SID>NextSection(2, 0, 0)<cr>

noremap <script> <buffer> <silent> []
        \ :call <SID>NextSection(2, 1, 0)<cr>

vnoremap <script> <buffer> <silent> ]]
        \ :<c-u>call <SID>NextSection(1, 0, 1)<cr>

vnoremap <script> <buffer> <silent> [[
        \ :<c-u>call <SID>NextSection(1, 1, 1)<cr>

vnoremap <script> <buffer> <silent> ][
        \ :<c-u>call <SID>NextSection(2, 0, 1)<cr>

vnoremap <script> <buffer> <silent> []
        \ :<c-u>call <SID>NextSection(2, 1, 1)<cr>


function! s:NextSection(type, backwards, visual)
    if a:visual
        normal! gv
    endif

    if a:type == 1
        let l:pattern = '\v(^\{|%^)' 
        let l:flags = 'e'
    elseif a:type == 2
        let l:pattern = '\v(^\s*\{|%^)'
        let l:flags = 'e'
    endif

    if a:backwards
        let l:dir = '?'
    else
        let l:dir = '/'
    endif

    execute 'silent normal! ' . l:dir . l:pattern . l:dir . l:flags . "\r"
endfunction
