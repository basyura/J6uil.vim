let s:save_cpo = &cpo
set cpo&vim

let s:api_root = 'http://lingr.com/api/'

function! J6uil#start(room)

  if !exists('s:lingr')
    let s:lingr = J6uil#lingr#new(g:J6uil_user, g:J6uil_password)
  else
    call s:lingr.verify_and_relogin()
  endif


  let messages = s:lingr.room_show(a:room)
  call J6uil#buffer#switch(a:room, messages)

  if !J6uil#thread#is_exists()
    let s:counter = s:lingr.subscribe()
    call s:lingr.observe(s:counter, function('J6uil#__update'))
  endif
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
  catch e
    echohl Error | echo 'error. stopped oberve lingr ' | echohl None
    return
  endtry
  
  if has_key(json, 'events')
    call J6uil#buffer#update(json)
  endif
  " if over 2 minutes return status ok only ?
  if has_key(json , 'counter')
    let s:counter = json.counter
  endif

  call s:lingr.observe(s:counter, function('J6uil#__update'))
endfunction

function! J6uil#say(room, message)
  return s:lingr.say(a:room, a:message)
endfunction


let &cpo = s:save_cpo
