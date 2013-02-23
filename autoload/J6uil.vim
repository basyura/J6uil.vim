let s:save_cpo = &cpo
set cpo&vim

let s:api_root = 'http://lingr.com/api/'

let s:J6uil = {'session' : ''}

let s:buf_name = 'J6uil'

let s:last_bufnr = 0


function! J6uil#start(room)

  if !exists('s:j6uil')
    let s:j6uil = J6uil#new(g:J6uil_user, g:J6uil_password)
    call s:j6uil.login()
    let s:counter = s:j6uil.subscribe()
    call s:j6uil.observe()
  endif

  if !s:j6uil.verify()
    call s:j6uil.observe()
    call s:j6uil.login()
  endif

  let s:room = a:room
  call s:switch_buffer()
  call s:buf_setting()
  call s:define_default_key_mappings()

  silent %delete _
  call append(0, '-- J6uil --')
  delete _
  "let s:counter = s:j6uil.subscribe(a:room)
  for message in  s:j6uil.room_show(a:room).rooms[0].messages
    let list = split(message.text, '\n')
    call append(line('$'), s:ljust(message.nickname, 12) . ' : ' . list[0])
    for msg in list[1:]
      call append(line('$'), s:ljust('', 12) . '   ' . msg)
    endfor
  endfor
  execute "normal! G"
  setlocal nomodified
    "setlocal noswapfile
    "setlocal nolist
    "setlocal nomodified
endfunction

function! s:J6uil.login()
  let ret = s:post('session/create', {
              \ 'app_key'  : '5xUaIa',
              \ 'user'     : self.username,
              \ 'password' : self.password,
              \ })

  let self.session = ret.session
  return self.session
endfunction

function! s:J6uil.destroy()
  return s:post('session/destroy', {
              \ 'app_key'  : '5xUaIa',
              \ 'session' : self.session,
              \ })
endfunction

function! s:J6uil.verify()
  return s:post('session/verify', {
              \ 'app_key'  : '5xUaIa',
              \ 'session' : self.session,
              \ }).status == 'ok'
endfunction

function! s:J6uil.get_rooms()
  return s:get('user/get_rooms', {'session' : self.session}).rooms
endfunction

function! s:J6uil.room_show(rooms)
  return s:get('room/show', {
        \ 'session' : self.session,
        \ 'rooms'   : [a:rooms],
        \ })
endfunction

function! s:J6uil.say(room, msg)
  return s:get('room/say', {
        \ 'session' : self.session,
        \ 'room'    : a:room,
        \ 'text'    : a:msg,
        \ })

endfunction

function! s:J6uil.subscribe(...)

  let rooms = a:0 ? a:1 : join(self.get_rooms(), ',')

  return s:get('room/subscribe', {
        \ 'session' : self.session,
        \ 'rooms' : rooms,
        \ }).counter
endfunction

function! s:update_buf(res)
  let res = a:res
  let pos = stridx(res, "\r\n\r\n")
  if pos != -1
    let content = strpart(res, pos+4)
  else
    let pos = stridx(res, "\n\n")
    let content = strpart(res, pos+2)
  endif

  let json = webapi#json#decode(content)
  
  if has_key(json, 'counter')
    let s:counter = json.counter
  endif
  call s:switch_buffer()
  call s:buf_setting()

  if has_key(json, 'status') && json.status == 'error'
    call append(line('$'), '')
    call append(line('$'), 'status : ' . json.status . ' code : ' . json.code . ' detail : ' . json.detail)
    call append(line('$'), '-- END --')
    return
  endif

  if has_key(json, 'events')
    for event in json.events
      if has_key(event, 'message')
        if event.message.room != s:room
          echo '[' . event.message.room . '] ' . event.message.nickname . ' : ' . substitute(event.message.text, '\n', '', 'g')
          continue
        endif
        let list = split(event.message.text, '\n')
        call append(line('$'), s:ljust(event.message.nickname, 12) . ' : ' . list[0])
        for msg in list[1:]
          call append(line('$'), s:ljust('', 12) . '   ' . msg)
        endfor

        "let msg = s:ljust(event.message.nickname, 12) . ' : ' . event.message.text
        "call append(line('$'), msg)
      else
        " online msg
        "echo event
      endif
    endfor
    execute "normal! G"
  endif
  setlocal nomodified

  call s:j6uil.observe()
  silent! call feedkeys("g\<Esc>", "n")
endfunction

function! s:J6uil.observe()
  let cmd = 'curl -L -s -k -i "http://lingr.com:8080/api/event/observe?session=' 
        \ . self.session . '&counter=' . string(s:counter) . '"'
  call g:thread(cmd, function('s:update_buf'))
endfunction

function! s:get(url, param)
  let res = webapi#http#get(s:api_root . a:url, a:param)
  return webapi#json#decode(res.content)
endfunction


function! s:post(url, param)
  let res = webapi#http#post(s:api_root . a:url, a:param)
  return webapi#json#decode(res.content)
endfunction

function! J6uil#new(username, password)
  let j6uil = deepcopy(s:J6uil)
  let j6uil.username = a:username
  let j6uil.password = a:password

  return j6uil
endfunction


function! s:post_message()
  call s:j6uil.say(s:room, s:get_text())
  bd!
endfunction

function! s:get_text()
  return matchstr(join(getline(1, '$'), "\n"), '^\_s*\zs\_.\{-}\ze\_s*$')
endfunction

function! s:release(threads)
    for thread in a:threads
        call thread.release()
    endfor
endfunction

if has_key(g:, "thread_list")
    call s:release(values(g:thread_list))
endif
let g:thread_list = {}

let g:thread_counter = 0


augroup vim-thread
    autocmd!
    autocmd! CursorHold,CursorHoldI * call s:update(values(g:thread_list))
augroup END

augroup vim-j6uil
    autocmd!
    autocmd! CursorHold * silent! call feedkeys("g\<Esc>", "n")
augroup END


function! s:update(threads)
    for thread in a:threads
        if !thread.is_finish
            call thread.update()
        endif
    endfor
endfunction


function! s:join(threads)
    while len(filter(copy(a:threads), "!v:val.is_finish"))
        call s:update(a:threads)
    endwhile
endfunction


function! s:thread_update(thread)
    let thread = a:thread
    let vimproc = thread.vimproc

    try
        if !vimproc.stdout.eof
            let thread.result .= vimproc.stdout.read()
        endif

        if !vimproc.stderr.eof
            let thread.result .= vimproc.stderr.read()
        endif

        if !(vimproc.stdout.eof && vimproc.stderr.eof)
            return 0
        endif
    catch
        echom v:throwpoint
    endtry

    call thread.finish()
endfunction

function! s:thread_entry(thread)
    let g:thread_list[g:thread_counter] = a:thread
    let a:thread.id = g:thread_counter
    let g:thread_counter += 1
endfunction


function! s:thread_release(thread)
    unlet g:thread_list[a:thread.id]
endfunction

function! s:make_thread(cmd, ...)
    let self = {
\       "id" : -1,
\       "is_finish" : 0,
\       "result" : "",
\       "command" : a:cmd,
\   }

    if a:0
        let self.apply = a:1
    endif
    
    function! self.update()
        call s:thread_update(self)
    endfunction
    
    function! self.run()
        call s:thread_entry(self)
        let vimproc = vimproc#pgroup_open(self.command)
        call vimproc.stdin.close()
        let self.vimproc = vimproc
    endfunction
    
    function! self.release()
        call s:thread_release(self)
        if !has_key(self, "vimproc")
            return
        endif
        call self.vimproc.stdout.close()
        call self.vimproc.stderr.close()
        call self.vimproc.waitpid()
    endfunction
    
    function! self.finish()
        let self.is_finish = 1
        try
            if has_key(self, "apply")
                call self.apply(self.result)
            endif
        finally
            call self.release()
        endtry
    endfunction

    return self
endfunction

function! g:thread(cmd, ...)
    let thread = call("s:make_thread", [a:cmd] + a:000)
    call thread.run()
    return thread
endfunction

function! s:switch_buffer()
  " get buf no from buffer's name
  let bufnr = -1
  let num   = bufnr('$')
  while num >= s:last_bufnr
    if getbufvar(num, '&filetype') ==# 'J6uil'
      let bufnr = num
      break
    endif
    let num -= 1
  endwhile
  " buf is not exist
  if bufnr < 0
    execute 'split ' . s:buf_name
    let s:last_bufnr = bufnr("")
    return
  endif
  " buf is exist in window
  let winnr = bufwinnr(bufnr)
  if winnr > 0
    execute winnr 'wincmd w'
    return
  endif
  " buf is exist
  if buflisted(bufnr)
    if g:tweetvim_open_buffer_cmd =~ "split"
      execute "split"
    endif
    execute 'buffer ' . bufnr
  else
    " buf is already deleted
    execute 'split ' . s:buf_name
    let s:last_bufnr = bufnr("")
  endif
endfunction

function! s:open_say_buffer()
  let text  = a:0 > 0 ? a:1 : ''
  let param = a:0 > 1 ? a:2 : {}
  
  let bufnr = bufwinnr('j6uil_say')
  if bufnr > 0
    exec bufnr.'wincmd w'
  else
    execute 'below split j6uil_say'
    execute '2 wincmd _'
    call s:define_default_settings_say()
  endif

  let &filetype = 'j6uil_say'

  startinsert!

  setlocal nomodified
endfunction

function! s:buf_setting()
  setlocal noswapfile
  setlocal modifiable
  setlocal nolist
  setlocal buftype=nofile
  setfiletype J6uil
  call s:define_default_key_mappings()
endfunction

function! s:define_default_key_mappings()
  augroup J6uil
    nnoremap <silent> <buffer> s :call <SID>open_say_buffer()<CR>
  augroup END
endfunction

function! s:define_default_settings_say()
  augroup J6uil_say
    nnoremap <silent> <buffer> <Enter> :call <SID>post_message()<CR>
    nnoremap <silent> <buffer> <C-j> :bd!<CR>
  augroup END
endfunction


function! s:ljust(str, size, ...)
  let str = a:str
  let c   = a:0 > 0 ? a:000[0] : ' '
  while 1
    if strwidth(str) >= a:size
      return str
    endif
    let str .= c
  endwhile
  return str
endfunction

let &cpo = s:save_cpo
