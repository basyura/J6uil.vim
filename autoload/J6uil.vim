let s:save_cpo = &cpo
set cpo&vim

let s:api_root = 'http://lingr.com/api/'

function! J6uil#start(room)

  let verified = 0

  if !exists('s:lingr')
    let s:lingr = J6uil#lingr#new(g:J6uil_user, g:J6uil_password)
  else
    let verified = s:lingr.verify_and_relogin()
  endif

  let messages = s:lingr.room_show(a:room)
  call J6uil#buffer#switch(a:room, messages)

  if !verified
    let s:counter = s:lingr.subscribe()
    call s:lingr.observe(s:counter, function('J6uil#__update'))
  endif
endfunction

function! J6uil#__update(res)
  let res = a:res
  let pos = stridx(res, "\r\n\r\n")
  if pos != -1
    let content = strpart(res, pos+4)
  else
    let pos = stridx(res, "\n\n")
    let content = strpart(res, pos+2)
  endif

  let json = webapi#json#decode(content)
  
  if has_key(json, 'events')
    call J6uil#buffer#update(json)
  endif
  " if over 2 minutes return status ok only ?
  if has_key(json , 'counter')
    let s:counter = json.counter
  endif

  call s:lingr.observe(s:counter, function('J6uil#__update'))


  "call s:buf_setting()

  "if has_key(json, 'status') && json.status == 'error'
    "call append(line('$'), '')
    "call append(line('$'), 'status : ' . json.status . ' code : ' . json.code . ' detail : ' . json.detail)
    "call append(line('$'), '-- END --')
    "return
  "endif

  "if has_key(json, 'events')
    "for event in json.events
      "if has_key(event, 'message')
        "if event.message.room != s:room
          "echo '[' . event.message.room . '] ' . event.message.nickname . ' : ' . substitute(event.message.text, '\n', '', 'g')
          "continue
        "endif
        "let list = split(event.message.text, '\n')
        "call append(line('$'), s:ljust(event.message.nickname, 12) . ' : ' . list[0])
        "for msg in list[1:]
          "call append(line('$'), s:ljust('', 12) . '   ' . msg)
        "endfor

        ""let msg = s:ljust(event.message.nickname, 12) . ' : ' . event.message.text
        ""call append(line('$'), msg)
      "else
        "" online msg
        ""echo event
      "endif
    "endfor
    "execute "normal! G"
  "endif
  "setlocal nomodified

  "call s:lingr.observe()
  "silent! call feedkeys("g\<Esc>", "n")
endfunction

"augroup vim-thread
    "autocmd!
    "autocmd! CursorHold,CursorHoldI * call s:update(values(g:thread_list))
"augroup END

"augroup vim-j6uil
    "autocmd!
    "autocmd! CursorHold * silent! call feedkeys("g\<Esc>", "n")
"augroup END




let &cpo = s:save_cpo
