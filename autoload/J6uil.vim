let s:save_cpo = &cpo
set cpo&vim

let s:api_root = 'http://lingr.com/api/'
let s:connect_time = localtime()

function! J6uil#subscribe(room)

  if !exists('s:lingr')
    try
      let user = exists('g:J6uil_user')     ? g:J6uil_user     : g:lingr_vim_user
      let pass = exists('g:J6uil_password') ? g:J6uil_password : g:lingr_vim_password
    catch
      echohl Error
      echo 'you must define g:J6uil_user or g:lingr_vim_user'
      echo '                g:J6uil_password or g:lingr_vim_password'
      echohl None
      return
    endtry
    let s:lingr = J6uil#lingr#new(user, pass)
  else
    call s:lingr.verify_and_relogin()
  endif

  let messages = s:lingr.room_show(a:room)
  call J6uil#buffer#switch(a:room, messages)

  call s:observe_start(s:lingr)

endfunction

function! J6uil#reconnect()
  let room = J6uil#buffer#current_room()
  if room == ''
    echo 'no connection'
    return
  endif
  call J6uil#buffer#switch(room, [])
  silent %delete _
  call J6uil#subscribe(room)
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
  echo  localtime() - s:connect_time
  if (localtime() - s:connect_time) <= 150
    return
  endif

  try
    call s:lingr.verify_and_relogin()
    call s:observe_start(s:lingr)
    echohl Error | echomsg "check connection is over limit. so connected"  | echohl None
  catch
    redraw
    echohl Error | echomsg "retried ... "  | echohl None
    call J6uil#buffer#append_message('reconnecting ...')
    sleep 2
    call s:check_connection()
    " to delete refresh buffer
    "let s:current_room = ''
    "call J6uil#subscribe(a:J6uil_current_room)
  endtry
endfunction

augroup J6uil
    autocmd!
    autocmd! CursorHold * call s:check_connection()
augroup END

let &cpo = s:save_cpo
