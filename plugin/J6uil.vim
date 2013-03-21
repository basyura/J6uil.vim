let s:save_cpo = &cpo
set cpo&vim

let g:J6uil_display_offline = 0
let g:J6uil_display_online  = 0
let g:J6uil_echo_presence   = 1
let g:J6uil_display_icon    = 0

if !isdirectory(expand("~/.J6uil/icon"))
  call mkdir(expand("~/.J6uil/icon"), 'p')
endif

command! -nargs=1 J6uil :call s:start(<f-args>)

command! -nargs=0 J6uilReconnect :call J6uil#reconnect()

function! s:start(room)
  call J6uil#subscribe(a:room)
endfunction

let &cpo = s:save_cpo
