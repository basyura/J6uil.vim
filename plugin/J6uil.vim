let s:save_cpo = &cpo
set cpo&vim

let g:J6uil_display_offline = 0
let g:J6uil_display_online  = 0
let g:J6uil_echo_presence   = 1

command! -nargs=1 J6uil :call s:start(<f-args>)

function! s:start(room)
  call J6uil#subscribe(a:room)
endfunction

let &cpo = s:save_cpo
