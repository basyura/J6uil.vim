let s:save_cpo = &cpo
set cpo&vim

command! -nargs=1 J6uil :call s:start(<f-args>)

function! s:start(room)
  call J6uil#subscribe(a:room)
endfunction

let &cpo = s:save_cpo
