
function! J6uil#action#open_links#execute()
  let text = getline(".")
  while 1
    let matched = matchlist(text, 'https\?://[0-9A-Za-z_#?~=\-+%\.\/:]\+')
    if len(matched) == 0
      break
    endif
    let url = matched[0]
    execute "OpenBrowser " . url

    let url  = substitute(url, '\~' , '\\~', 'g')
    let text = substitute(text , url , '' , 'g')
  endwhile
endfunction

