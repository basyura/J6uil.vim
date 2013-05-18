let s:save_cpo = &cpo
set cpo&vim

let s:Vital    = vital#of('J6uil')
let s:DateTime = s:Vital.import('DateTime')

let s:last_bufnr      = 0
let s:current_room    = '' 
let s:before_msg_user = ''

function! s:config()
  return J6uil#config()
endfunction

function! J6uil#buffer#current_room()
  return s:current_room
endfunction

function! J6uil#buffer#switch(room, status)
  let s:current_room = a:room
  call s:switch_buffer()
  call s:buf_setting()

  execute "sign unplace * buffer=" . bufnr("%")
"  if !exists('b:J6uil_current_room') || b:J6uil_current_room != a:room
    silent %delete _
"  endif

  let b:J6uil_current_room = a:room
  let b:J6uil_roster = a:status.roster

  for message in a:status.messages
    call s:update_message(message, '$', 0)
  endfor

  call append(line('$'), '-- room : ' . a:room . ' --')
  delete _

  execute "normal! G"
  setlocal nomodified
  setlocal nomodifiable
  call s:cache_buffer()
endfunction

let s:que = []

function! J6uil#buffer#is_current()
  return bufname("%") == s:config().buf_name
endfunction

function! J6uil#buffer#has_que()
  return len(s:que) > 0
endfunction

function! J6uil#buffer#update(json)

  call add(s:que, a:json) 

  if !J6uil#buffer#is_current()
    return
  endif

  call s:switch_buffer()
  call s:buf_setting()

  let is_bottom = line(".") == line("$")

  let cnt = 0
  for json in s:que
    let cnt += s:update(json.events)
  endfor

  if is_bottom && cnt
    execute "normal! G"
    execute "normal! \<C-e>"
  elseif cnt
    execute "normal! " . cnt . "\<C-e>"
  else
    call feedkeys("g\<Esc>", "n")
  endif

  let s:que = []

  setlocal nomodified
  setlocal nomodifiable
endfunction

function! J6uil#buffer#append_message(message)
  call s:switch_buffer()
  call s:buf_setting()
  call append(line('$'), a:message)
endfunction

function! J6uil#buffer#load_archives(room, messages)

  setlocal modifiable

  let s:before_msg_user = ''
  " 暫定
  delete _
    "execute "normal! " . cnt . "\<Down>"
  for message in a:messages
    let cnt = s:update_message(message, '.', -1)
    "execute "normal! " . cnt . "\<Down>"
  endfor

  call append(0, s:config().archive_statement)

  let  b:J6uil_oldest_id = a:messages[0].id
  setlocal nomodifiable
endfunction
"
"
function! s:update(events)
  let counter = 0
  for event in  a:events
    if has_key(event, 'message')
      if event.message.room != s:current_room
        continue
      endif
      call s:update_message(event.message, '$', 0)
      let counter += 1
    elseif has_key(event, 'presence')
      if event.presence.room != s:current_room
        continue
      endif
      call s:update_presence(event.presence)
    endif
  endfor
  " cache for say buffer
  if counter > 0
    call s:cache_buffer()
  endif
  return counter
endfunction
"
"
function! s:update_message(message, line_expr, cnt)
  " check duplicate message
  if !exists('b:J6uil_latest_message_id')
    let b:J6uil_latest_message_id = 0
  end
  if b:J6uil_latest_message_id == a:message.id
    return
  end
  let b:J6uil_latest_message_id = a:message.id

  let message = a:message
  let list = split(message.text, '\n')

  let date_time = s:DateTime.from_format(message.timestamp . ' +0000', '%Y-%m-%dT%H:%M:%SZ %z', 'C')
  let list[-1] = list[-1] . '  [[' . date_time.strftime("%m/%d %H:%M") . ']]'

  let nickname = message.nickname
  if nickname == s:before_msg_user || nickname == 'URL Info.'
    let nickname = s:config().blank_nickname
  else
    let s:before_msg_user = nickname
    let nickname = (g:J6uil_display_icon ?  ' ' : '') . s:ljust(nickname, 12) . (g:J6uil_display_icon ?  '' : ' ') . ' : '
  endif

  if getline(1) == ''
    call append(0, s:config().archive_statement)
    let  b:J6uil_oldest_id = message.id
  end

  if g:J6uil_display_separator && nickname != s:config().blank_nickname
    call append(line(a:line_expr) + a:cnt, s:separator("-"))
  end


  call append(line(a:line_expr) + a:cnt, nickname . list[0])

  if g:J6uil_display_icon && substitute(nickname, ' ', '', 'g') != ''
    let current_dir = getcwd()
    execute "cd " . g:J6uil_config_dir
    let ico_path  = g:J6uil_config_dir . '/icon/' . message.speaker_id . ".ico"
    let img_url   = message.icon_url
    let file_name = fnamemodify(img_url, ":t")

    if !filereadable(ico_path)
      "echo "downloading " . message.nickname . "'s avatar ... " . img_url
      call system("curl -L -O " . img_url)
      call system("convert " . fnamemodify(img_url, ":t") . " " . ico_path)
      call delete(file_name)
      redraw
    endif

    execute "cd " . current_dir

    try
      execute ":sign define J6uil_icon_" . message.speaker_id . " icon=" . ico_path
      execute ":sign place 1 line=" . (line(a:line_expr) + a:cnt) . " name=J6uil_icon_" . message.speaker_id . " buffer=" . bufnr("%")
    catch
      echohl Error | echomsg message.nickname . ' ' .  v:exception | echohl None
    endtry
  endif

  for msg in list[1:]
    call append(line(a:line_expr) + a:cnt, s:ljust('', 12) . '    ' . msg)
  endfor

  return len(list) 
endfunction
"
"
function! s:update_presence(presence)
  if g:J6uil_echo_presence
    echo a:presence.text
  endif
  if !g:J6uil_insert_offline && a:presence.status == 'offline'
    return
  endif
  if !g:J6uil_insert_online  && a:presence.status == 'online'
    return
  endif
  call append(line('$'), s:ljust('', 12) . '   ' . a:presence.text)
endfunction
"
"
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
    execute g:J6uil_open_buffer_cmd . ' ' . s:config().buf_name
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
    if g:J6uil_open_buffer_cmd =~ "split"
      execute "split"
    endif
    execute 'buffer ' . bufnr
  else
    " buf is already deleted
    execute 'split ' . s:config().buf_name
    let s:last_bufnr = bufnr("")
  endif
endfunction
"
"
function! s:buf_setting()
  setlocal noswapfile
  setlocal modifiable
  setlocal nolist
  setlocal nonu
  setlocal buftype=nofile
  hi Signcolumn guibg=bg
  call s:define_default_key_mappings()
  setfiletype J6uil

  if !exists('b:J6uil_saved_updatetime')
    let b:J6uil_saved_updatetime = &updatetime
  endif
  let &updatetime = g:J6uil_updatetime
  augroup J6uil-buffer
    autocmd!
    "autocmd! CursorHold <buffer> silent! call feedkeys("g\<Esc>", "n")
    autocmd! WinEnter   <buffer> execute "let &updatetime=" . g:J6uil_updatetime
    autocmd! BufLeave   <buffer> execute "let &updatetime=" . b:J6uil_saved_updatetime
    autocmd! BufUnload  <buffer> :J6uilDisconnect
  augroup END
endfunction
"
"
function! s:define_default_key_mappings()
  augroup J6uil_buffer
    nmap <silent> <buffer> s                 <Plug>(J6uil_open_say_buffer)
    nmap <silent> <buffer> <Leader><Leader>r <Plug>(J6uil_reconnect)
    nmap <silent> <buffer> <Leader><Leader>d <Plug>(J6uil_disconnect)
    nmap <silent> <buffer> <Leader>r         <Plug>(J6uil_unite_rooms)
    nmap <silent> <buffer> <Leader>u         <Plug>(J6uil_unite_members)
    nmap <silent> <buffer> <CR>              <Plug>(J6uil_action_enter)
    nmap <silent> <buffer> o                 <Plug>(J6uil_action_open_links)
  augroup END
endfunction
"
"
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
"
"
function! s:cache_buffer()
  if exists(":NeoComplCacheCachingBuffer")
    :NeoComplCacheCachingBuffer
  endif
endfunction
"
"
function! s:separator(s)
  let max = s:bufwidth() - (g:J6uil_display_icon ? 2 : 0)

  let sep = ""
  while len(sep) < max
    let sep .= a:s
  endwhile
  return sep
endfunction
"
"
function! s:bufwidth()
  let width = winwidth(0)
  if &l:number || &l:relativenumber
    let width = width - (&numberwidth + 1)
  endif
  return width
endfunction

let &cpo = s:save_cpo
