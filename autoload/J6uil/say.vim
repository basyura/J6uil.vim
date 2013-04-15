

function! J6uil#say#open(room)
  let text  = a:0 > 0 ? a:1 : ''
  let param = a:0 > 1 ? a:2 : {}
  
  let bufnr = bufwinnr('j6uil_say')
  if bufnr > 0
    exec bufnr.'wincmd w'
  else
    execute 'below split j6uil_say'
    execute '2 wincmd _'
    call s:define_default_settings_say()
  endif

  let &filetype = 'J6uil_say'

  let b:J6uil_current_room = a:room

  startinsert!

  setlocal nomodified
endfunction

function! s:define_default_settings_say()
  augroup J6uil_say
    nnoremap <silent> <buffer> <Enter> :call <SID>post_message()<CR>
    inoremap <silent> <buffer> <C-CR>  <ESC>:call <SID>post_message()<CR>
    nnoremap <silent> <buffer> <C-j> :bd!<CR>
    setlocal nonu
  augroup END
endfunction

function! s:post_message()
  let text = s:get_text()
  if J6uil#say(b:J6uil_current_room, text)
    bd!
  endif
endfunction

function! s:get_text()
  return matchstr(join(getline(1, '$'), "\n"), '^\_s*\zs\_.\{-}\ze\_s*$')
endfunction
