let s:save_cpo = &cpo
set cpo&vim

let s:api_root = 'http://lingr.com/api/'

let s:lingr = {'session' : ''}

function! J6uil#lingr#new(username, password)
  let lingr = deepcopy(s:lingr)
  let lingr.username = a:username
  let lingr.password = a:password
  return j6uil
endfunction

function! s:lingr.login()
  let ret = s:post('session/create', {
              \ 'app_key'  : '5xUaIa',
              \ 'user'     : self.username,
              \ 'password' : self.password,
              \ })

  let self.session = ret.session
  return self.session
endfunction

function! s:lingr.destroy()
  return s:post('session/destroy', {
              \ 'app_key'  : '5xUaIa',
              \ 'session' : self.session,
              \ })
endfunction

function! s:lingr.verify()
  return s:post('session/verify', {
              \ 'app_key'  : '5xUaIa',
              \ 'session' : self.session,
              \ }).status == 'ok'
endfunction

function! s:lingr.get_rooms()
  return s:get('user/get_rooms', {'session' : self.session}).rooms
endfunction

function! s:lingr.room_show(rooms)
  return s:get('room/show', {
        \ 'session' : self.session,
        \ 'rooms'   : [a:rooms],
        \ })
endfunction

function! s:lingr.say(room, msg)
  return s:get('room/say', {
        \ 'session' : self.session,
        \ 'room'    : a:room,
        \ 'text'    : a:msg,
        \ })

endfunction

function! s:lingr.subscribe(...)

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

function! s:lingr.observe()
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


let &cpo = s:save_cpo
