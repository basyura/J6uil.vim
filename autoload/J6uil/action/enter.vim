
function! J6uil#action#enter#execute()
  if getline(".") == J6uil#config().archive_statement
    call J6uil#load_archives(b:J6uil_current_room, b:J6uil_oldest_id)
    return
  endif

  let word = expand('<cWORD>')
  let matched = matchstr(word, 'https\?://\%([0-9A-Za-z.-]\+\|\[[0-9A-Fa-f:]\+\]\)\%(:[0-9]\+\)\?\%(/[^[:blank:]"<>\\^`{|}]\+\)\?')
  if matched !=# ''
    execute "OpenBrowser " . matched
    return
  endif
endfunction
