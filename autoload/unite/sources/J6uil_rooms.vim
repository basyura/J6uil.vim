let s:save_cpo = &cpo
set cpo&vim

function! unite#sources#J6uil_rooms#define()
  return s:source
endfunction

let s:source = {
      \ 'name': 'J6uil/rooms',
      \ 'action_table'   : {},
      \ 'default_action' : {'common' : 'execute'},
      \ }

function! s:source.gather_candidates(args, context)
  return map(J6uil#get_rooms() , '{
             \ "word" : v:val,
             \ }')
endfunction

let s:source.action_table.execute = {'description' : 'change room'}
function! s:source.action_table.execute.func(candidate)
  let room = a:candidate.word
  call J6uil#subscribe(room)
endfunction

let &cpo = s:save_cpo
