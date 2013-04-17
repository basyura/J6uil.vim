let s:save_cpo = &cpo
set cpo&vim

let s:api_root = 'http://lingr.com/api/'
let s:connect_time = localtime()

function! J6uil#subscribe(room)

  augroup J6uil
    autocmd!
    autocmd! CursorHold * call s:check_connection()
  augroup END

  if !exists('s:lingr')
    try
      let user = exists('g:J6uil_user')     ? g:J6uil_user     : exists('g:lingr_vim_user')     ? g:lingr_vim_user     : input('user : ')
      let pass = exists('g:J6uil_password') ? g:J6uil_password : exists('g:lingr_vim_password') ? g:lingr_vim_password : input('password : ')
    catch
      echohl Error
      echo 'you must define g:J6uil_user or g:lingr_vim_user'
      echo '                g:J6uil_password or g:lingr_vim_password'
      echohl None
      return
    endtry
    try
      let s:lingr = J6uil#lingr#new(user, pass)
    catch
      call J6uil#disconnect()
      redraw
      echohl Error | echo "failed to login \n" . v:exception | echohl None
      return
    endtry
  else
    call s:lingr.verify_and_relogin()
  endif

  let room = a:room
  if room == ''
    let rooms = J6uil#get_rooms()
    let room = rooms[0]
  end


  let status = s:lingr.room_show(room)
  call J6uil#buffer#switch(room, status)

  call s:observe_start(s:lingr)
endfunction


function! J6uil#reconnect()
  let room = J6uil#buffer#current_room()
  if room == ''
    echo 'no connection'
    return
  endif
  " todo
  call J6uil#buffer#switch(room, {
        \ 'messages' : [], 
        \ 'roster'   : {'members' : [], 'bots' : []}
        \ })
  set modifiable
  silent %delete _
  call J6uil#subscribe(room)
  echohl Error | echo "reconnected to " . room  | echohl None
endfunction

function! J6uil#disconnect()
  augroup J6uil
    autocmd!
  augroup END
  if exists('b:saved_updatetime')
    let &updatetime = b:saved_updatetime
  endif
  echohl Error | echo '-- disconnected --' | echohl None
endfunction

function! J6uil#load_archives(room, oldest_id)
  let messages = s:lingr.get_archives(a:room, a:oldest_id)
  call J6uil#buffer#load_archives(a:room, messages)
endfunction

function! J6uil#get_rooms()
  return s:lingr.get_rooms()
endfunction

function! s:observe_start(lingr)
  " めちゃくちゃになってきたな・・・
  let lingr = a:lingr
  call J6uil#thread#release()
  let s:counter = lingr.subscribe()
  call lingr.observe(s:counter, function('J6uil#__update'))
  let s:connect_time = localtime()
endfunction

function! J6uil#__update(res)
  try
    let res = a:res
    let pos = stridx(res, "\r\n\r\n")
    if pos != -1
      let content = strpart(res, pos+4)
    else
      let pos = stridx(res, "\n\n")
      let content = strpart(res, pos+2)
    endif

    let json = webapi#json#decode(content)
  catch
    " normal? error
    if a:res != ''
      call J6uil#buffer#append_message('error. retried oberve lingr ')
      echohl Error | echo 'error. retried oberve lingr ' | echohl None
      call s:lingr.observe(s:counter, function('J6uil#__update'))
      let s:connect_time = localtime()
    endif
    return
  endtry
  
  if J6uil#thread#has_many()
    echohl Error | echomsg  "thread count is " .  string(J6uil#thread#count()) | echohl None
    return
  endif

  if has_key(json, 'events')
    call J6uil#buffer#update(json)
  endif

  " if over 2 minutes return status ok only ?
  if has_key(json , 'counter')
    let s:counter = json.counter
  endif

  let s:connect_time = localtime()
  call s:lingr.observe(s:counter, function('J6uil#__update'))
endfunction

function! J6uil#say(room, message)
  return s:lingr.say(a:room, a:message)
endfunction

function! s:check_connection()
  silent! call feedkeys("g\<Esc>", "n")
  " debug
  if g:J6uil_debug_mode
    echo ' connection ' . (J6uil#thread#is_exists() ? 'ok' : 'ng') . ' : ' .  string(localtime() - s:connect_time)
  endif

  " for : j6uil → unite → j6uil
  if J6uil#buffer#is_current()
    let &updatetime = g:J6uil_updatetime
  endif

  " for reenter to J6uil's buffer
  if J6uil#buffer#has_que()
    call J6uil#buffer#update({'events' : []})
  endif

  " check connection
  if J6uil#thread#is_exists() && (localtime() - s:connect_time) <= 150
    return
  endif

  try
    echohl Error | echo "check connection :  over time. trying to reconnect ..."  | echohl None
    call J6uil#reconnect()
  catch
    redraw
    echohl Error | echo "retried ... "  | echohl None
    call J6uil#buffer#append_message('reconnecting ...')
    sleep 2
    call s:check_connection()
  endtry
endfunction

let &cpo = s:save_cpo
