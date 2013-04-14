let s:save_cpo = &cpo
set cpo&vim

function! s:set(key, default)
  if !has_key(g:, a:key)  
    let g:[a:key] = a:default
  endif
endfunction

call s:set('J6uil_display_offline' , 0)
call s:set('J6uil_display_online'  , 0)
call s:set('J6uil_echo_presence'   , 1)
call s:set('J6uil_display_icon'    , 0)
call s:set('J6uil_display_interval', 0)
call s:set('J6uil_updatetime'      , 1000)
call s:set('J6uil_open_buffer_cmd' , 'edit!')

if !isdirectory(expand("~/.J6uil/icon"))
  call mkdir(expand("~/.J6uil/icon"), 'p')
endif

command! -nargs=? J6uil :call s:start(<f-args>)

command! -nargs=0 J6uilReconnect :call J6uil#reconnect()

command! -nargs=0 J6uilDisconnect :call J6uil#disconnect()

function! s:start(...)
  let room = a:0 ? a:1 : ''
  call J6uil#subscribe(room)
endfunction

let &cpo = s:save_cpo
