let s:save_cpo = &cpo
set cpo&vim

let s:buf_name = 'J6uil'

let s:last_bufnr = 0

let s:current_room = '' 


augroup J6uil-buffer
    autocmd!
    autocmd! CursorHold * silent! call feedkeys("g\<Esc>", "n")
augroup END

function! J6uil#buffer#switch(room, messages)
  let s:current_room = a:room
  call s:switch_buffer()
  call s:buf_setting()

  if exists('b:J6uil_current_room') && b:J6uil_current_room != a:room
    silent %delete _
    call append(0, '--' . a:room . '--')
    delete _
  endif

  let b:J6uil_current_room = a:room

  for message in a:messages
    call s:update_message(message)
  endfor

  execute "normal! G"
  setlocal nomodified
endfunction

function! J6uil#buffer#update(json)
  call s:switch_buffer()
  call s:buf_setting()

  if s:update(a:json.events) > 0
    execute "normal! G"
  endi

  setlocal nomodified
endfunction

function! s:update(events)
  let counter = 0
  for event in  a:events
    if has_key(event, 'message')
      if event.message.room != s:current_room
        continue
      endif
      call s:update_message(event.message)
    elseif has_key(event, 'presence')
      if event.presence.room != s:current_room
        continue
      endif
      call s:update_presence(event.presence)
    endif
    let counter += 1
  endfor
  return counter
endfunction

function! s:update_message(message)
  let message = a:message
  let list = split(message.text, '\n')
  call append(line('$'), s:ljust(message.nickname, 12) . ' : ' . list[0])
  for msg in list[1:]
    call append(line('$'), s:ljust('', 12) . '   ' . msg)
  endfor
endfunction

function! s:update_presence(presence)
  call append(line('$'), s:ljust('', 12) . '   ' . a:presence.text)
endfunction

function! s:switch_buffer()
  " get buf no from buffer's name
  let bufnr = -1
  let num   = bufnr('$')
  while num >= s:last_bufnr
    if getbufvar(num, '&filetype') ==# 'J6uil'
      let bufnr = num
      break
    endif
    let num -= 1
  endwhile
  " buf is not exist
  if bufnr < 0
    execute 'split ' . s:buf_name
    let s:last_bufnr = bufnr("")
    return
  endif
  " buf is exist in window
  let winnr = bufwinnr(bufnr)
  if winnr > 0
    execute winnr 'wincmd w'
    return
  endif
  " buf is exist
  if buflisted(bufnr)
    if g:tweetvim_open_buffer_cmd =~ "split"
      execute "split"
    endif
    execute 'buffer ' . bufnr
  else
    " buf is already deleted
    execute 'split ' . s:buf_name
    let s:last_bufnr = bufnr("")
  endif
endfunction

function! s:open_say_buffer()
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

  let &filetype = 'j6uil_say'

  startinsert!

  setlocal nomodified
endfunction

function! s:buf_setting()
  setlocal noswapfile
  setlocal modifiable
  setlocal nolist
  setlocal nonu
  setlocal buftype=nofile
  call s:define_default_key_mappings()
  setfiletype J6uil
endfunction

function! s:define_default_key_mappings()
  augroup J6uil_buffer
    nnoremap <silent> <buffer> s :call <SID>open_say_buffer()<CR>
  augroup END
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
  if J6uil#say(s:current_room, text)
    bd!
  endif
endfunction

function! s:get_text()
  return matchstr(join(getline(1, '$'), "\n"), '^\_s*\zs\_.\{-}\ze\_s*$')
endfunction

function! s:ljust(str, size, ...)
  let str = a:str
  let c   = a:0 > 0 ? a:000[0] : ' '
  while 1
    if strwidth(str) >= a:size
      return str
    endif
    let str .= c
  endwhile
  return str
endfunction

let &cpo = s:save_cpo
