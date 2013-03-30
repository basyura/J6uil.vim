
function! unite#sources#J6uil_members#define()
  return s:source
endfunction

let s:source = {
      \ 'name': 'J6uil/members',
      \ 'action_table'   : {},
      \ 'default_action' : {'common' : 'execute'},
      \ 'is_listed'      : 0,
      \ }

function! s:source.gather_candidates(args, context)
  " members : ['timestamp', 'pokeable', 'name', 'is_online', 'username', 'is_owner', 'icon_url'] 
  return map(copy(b:J6uil_roster.members), '{
             \ "word" : v:val.name,
             \ "abbr" : (v:val.is_online ? "+ " : "  ") .  v:val.name,
             \ }')
endfunction

let s:source.action_table.execute = {'description' : 'show users'}
function! s:source.action_table.execute.func(candidate)
  let room = a:candidate.word
  call J6uil#subscribe(room)
endfunction
