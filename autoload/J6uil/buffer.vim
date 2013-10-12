scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:Vital    = vital#of('J6uil')
let s:DateTime = s:Vital.import('DateTime')

let s:last_bufnr      = 0
let s:before_msg_user = ''
let s:unconvertibles  = {}

let s:cacheMgr = J6uil#cache_manager#new()

function! s:config()
  return J6uil#config()
endfunction

function! J6uil#buffer#current_room()
  return s:cacheMgr.current_room()
endfunction

"
"
function! J6uil#buffer#layout(rooms)

  let s:cacheMgr.rooms = a:rooms

  if !g:J6uil_multi_window
    return
  endif

  let rooms = a:rooms

  silent! only

  " members
  silent! vsplit J6uil_members
  setlocal noswapfile
  setlocal nolist
  setlocal nonu
  setlocal buftype=nofile
  setlocal statusline=\ members
  setfiletype J6uil_members

  " rooms
  silent! split  J6uil_rooms
  setlocal noswapfile
  setlocal nolist
  setlocal nonu
  setlocal buftype=nofile
  setlocal statusline=\ rooms
  setfiletype J6uil_rooms

  10 wincmd |
  execute (len(rooms) + 2) . ' wincmd _'
  wincmd l
endfunction


function! J6uil#buffer#switch(room, status)
  call s:cacheMgr.current_room(a:room)
  call s:switch_buffer()
  call s:buf_setting()

  execute "sign unplace * buffer=" . bufnr("%")
  silent %delete _

  let b:J6uil_current_room = a:room
  let b:J6uil_roster = a:status.roster
  call s:cacheMgr.cache_presence(a:room, a:status.roster.members)
  call s:update_status()

  for message in a:status.messages
    call s:update_message(message, '$', 0)
  endfor

  call append(line('$'), '-- room : ' . a:room . ' --')
  delete _

  execute "normal! G"
  setlocal nomodified
  setlocal nomodifiable

  redraw!
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

  redraw

  call s:update_status()

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

  if getline(1) != s:config().archive_statement
    call append(0, s:config().archive_statement)
  endif

  let  b:J6uil_oldest_id = a:messages[0].id
  setlocal nomodifiable
endfunction
"
"
function! J6uil#buffer#statusline()
  let status = ''
  for cache in s:cacheMgr.get_cache()
    let cnt = cache.unread_count
    if cnt > 0
      let status .= cache.room . '(' . string(cnt) . ') '
    endif
  endfor
  if status == ''
    let status = 'no updated message'
  endif
  "while len(status) < winwidth(0) - 4
    "let status = ' ' . status
  "endwhile
  let status = "%=" . status . ' '
  let status .= "%{printf('%5d/%d',line('.'),line('$'))}"
  return status
endfunction
"
"
function! s:update(events)
  let counter = 0
  for event in  a:events
    if has_key(event, 'message')
      if event.message.room != s:cacheMgr.current_room()
        call s:cache(event.message, 0)
        "echo s:truncate('[' . event.message.room . '] ' . event.message.nickname . ' : ' . split(event.message.text, '\n')[0], winwidth(0) - 20)
        "
      else
        call s:cache(event.message, 1)
        call s:update_message(event.message, '$', 0)
        let counter += 1
      endif
      "redraw!
      "echo J6uil#buffer#statusline()
    elseif has_key(event, 'presence')
      if event.presence.room != s:cacheMgr.current_room()
        continue
      endif
      call s:update_presence(event.presence)
    endif
  endfor

  return counter
endfunction
"
function! s:update_icon(message, line_expr, cnt, nickname)
  if !s:is_display_icon() || substitute(a:nickname, ' ', '', 'g') == '' || get(s:unconvertibles, a:message.speaker_id, 0)
    return
  endif

  let current_dir = getcwd()
  execute "cd " . g:J6uil_config_dir
  let ico_path  = g:J6uil_config_dir . '/icon/' . a:message.speaker_id . ".ico"
  let img_url   = a:message.icon_url
  let file_name = fnamemodify(img_url, ":t")

  if !filereadable(ico_path)
    "echo "downloading " . a:message.nickname . "'s avatar ... " . img_url
    call system("curl -L -O " . img_url)
    call system("convert " . fnamemodify(img_url, ":t") . " " . ico_path)
    call delete(file_name)
    if v:shell_error
      let s:unconvertibles[a:message.speaker_id] = 1
      return
    endif
    redraw
  endif

  execute "cd " . current_dir

  try
    execute ":sign define J6uil_icon_" . a:message.speaker_id . " icon=" . ico_path
    execute ":sign place 1 line=" . (line(a:line_expr) + a:cnt) . " name=J6uil_icon_" . a:message.speaker_id . " buffer=" . bufnr("%")
  catch
    echohl Error | echomsg a:message.nickname . ' ' .  v:exception | echohl None
  endtry
endfunction
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

  if empty(list)
    return 0
  endif

  let date_time = s:DateTime.from_format(message.timestamp . ' +0000', '%Y-%m-%dT%H:%M:%SZ %z', 'C')
  let list[-1] = list[-1] . '  ' . date_time.strftime("%m/%d %H:%M")

  let nickname = message.nickname
  if nickname == s:before_msg_user || nickname == 'URL Info.'
    let nickname = s:config().blank_nickname
  else
    let s:before_msg_user = nickname
    let nickname = (s:is_display_icon() ?  ' ' : '') . s:ljust(nickname, g:J6uil_nickname_length) . (s:is_display_icon() ?  '' : ' ') . ' : '
  endif

  if getline(1) == ''
    call append(0, s:config().archive_statement)
    let  b:J6uil_oldest_id = message.id
  end

  if (g:J6uil_display_separator || g:J6uil_empty_separator) && nickname != s:config().blank_nickname
    let separator = g:J6uil_empty_separator ? '' : s:separator("-")
    call append(line(a:line_expr) + a:cnt, separator)
  endif



  call append(line(a:line_expr) + a:cnt, nickname .
        \ (g:J6uil_align_message ? list[0] : ''))

  call s:update_icon(message, a:line_expr, nickname, a:cnt)

  if g:J6uil_align_message
    for msg in list[1:]
      call append(line(a:line_expr) + a:cnt,
            \ s:ljust('', g:J6uil_nickname_length) . '    ' . msg)
    endfor
  else
    for msg in list
      call append(line(a:line_expr) + a:cnt, ' ' . msg)
    endfor
  endif

  return len(list)
endfunction
"
"
function! s:update_presence(presence)
  " cache user status
  call s:cacheMgr.cache_presence(a:presence.room, a:presence)

  if g:J6uil_echo_presence
    redraw!
    echo a:presence.text
  endif
  if !g:J6uil_insert_offline && a:presence.status == 'offline'
    return
  endif
  if !g:J6uil_insert_online  && a:presence.status == 'online'
    return
  endif
  call append(line('$'), s:ljust('', g:J6uil_nickname_length) . '   ' . a:presence.text)
endfunction

function! s:update_status()
  if !g:J6uil_multi_window
    return
  endif

  wincmd h
  " room
  wincmd k
  0
  if expand('%') == 'J6uil_rooms'
    setlocal modifiable
    silent %delete _
    for room in s:cacheMgr.rooms
      let mark = room == s:cacheMgr.current_room() ? '* ' : '  '
      let mcnt = s:cacheMgr.get_unread_count(room)
      if mcnt != 0
        call append(line('.') - 1, mark . room . ' (' . string(mcnt) . ')')
      else
        call append(line('.') - 1, mark . room)
      endif
    endfor
    delete _
    0
    setlocal nomodified
    setlocal nomodifiable
  endif
  " member
  wincmd j
  if expand('%') == 'J6uil_members'
    0
    setlocal modifiable
    silent %delete _
    for member in sort(s:cacheMgr.get_members(s:cacheMgr.current_room()), 'J6uil#buffer#_member_sorter')
      let name  = member.is_online ? '+' : ' '
      let name .= member.is_owner  ? '*' : ' '
      let name .= member.name
      call append(0, name)
    endfor
    delete _
    setlocal nomodified
    setlocal nomodifiable
    0
  endif
  " message
  wincmd l
  
endfunction

function! J6uil#buffer#_member_sorter(i1, i2)
  if a:i1.is_owner && a:i2.is_owner
	  return a:i1.name == a:i2.name ? 0 : a:i1.name > a:i2.name ? -1 : 1
  else
    if a:i1.is_owner
      return 1
    elseif a:i2.is_owner
      return -1
    endif
  endif

  if a:i1.is_online && a:i2.is_online
	  return a:i1.name == a:i2.name ? 0 : a:i1.name > a:i2.name ? -1 : 1
  else
    if a:i1.is_online
      return 1
    elseif a:i2.is_online
      return -1
    endif
  endif


	return a:i1.name == a:i2.name ? 0 : a:i1.name > a:i2.name ? -1 : 1
endfunction
"
"
function! s:cache(message, is_read)
  let message = a:message

  if !a:is_read
    call s:cacheMgr.count_up_unread(message.room)
  endif
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
    silent! execute g:J6uil_open_buffer_cmd . ' ' . s:config().buf_name
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

  if !g:J6uil_no_default_keymappings
    call s:define_default_key_mappings()
  endif

  setfiletype J6uil

  if !exists('b:J6uil_saved_updatetime')
    let b:J6uil_saved_updatetime = &updatetime
  endif

  setlocal statusline=%!J6uil#buffer#statusline()

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
function! s:separator(s)
  let max = s:bufwidth() - (s:is_display_icon() ? 2 : 0)

  let sep = ""
  while len(sep) < max
    let sep .= a:s
  endwhile
  return sep
endfunction
"
"
function! s:bufwidth()
  let width = winwidth(0) - &l:foldcolumn
  if &l:number || &l:relativenumber
    let width = width - (&numberwidth + 1)
  endif
  return width
endfunction

function! s:is_display_icon()
  return g:J6uil_display_icon && has('signs') && has('gui_running')
endfunction

function! s:truncate(message, width)
  let message = a:message
  while strwidth(message) > a:width
    let message = message[0:len(message) - 2]
  endwhile
  return message
endfunction

let &cpo = s:save_cpo
