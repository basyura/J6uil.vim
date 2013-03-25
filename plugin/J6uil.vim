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

if !isdirectory(expand("~/.J6uil/icon"))
  call mkdir(expand("~/.J6uil/icon"), 'p')
endif

command! -nargs=1 J6uil :call s:start(<f-args>)

command! -nargs=0 J6uilReconnect :call J6uil#reconnect()

function! s:start(room)
  call J6uil#subscribe(a:room)
endfunction

let &cpo = s:save_cpo
