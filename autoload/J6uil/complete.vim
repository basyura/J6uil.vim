
function! J6uil#complete#room(argLead, cmdLine, cursorPos)
  let rooms = get(g:, 'J6uil_cache_rooms', '')
  if rooms != ''
    return rooms
  endif

  if exists('g:J6uil_user') && exists('g:J6uil_password')
    let user = g:J6uil_user
    let pass = g:J6uil_password
  elseif exists('g:lingr_vim_user') && exists('g:lingr_vim_password')
    let user = g:lingr_vim_user
    let pass = g:lingr_vim_password
  else
    return ''
  endif

  let lingr = J6uil#lingr#new(user, pass)
  let g:J6uil_cache_rooms = join(lingr.get_rooms(), "\n")

  return g:J6uil_cache_rooms
endfunction
