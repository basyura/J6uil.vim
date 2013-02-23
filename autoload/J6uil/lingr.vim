let s:save_cpo = &cpo
set cpo&vim

let s:api_root = 'http://lingr.com/api/'

let s:lingr = {'session' : ''}

function! J6uil#lingr#new(username, password)
  let lingr = deepcopy(s:lingr)
  let lingr.username = a:username
  let lingr.password = a:password

  call lingr.login()
  return lingr
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

function! s:lingr.verify_and_relogin()
  if self.verify()
    return 1
  endif

  call s:lingr.login()
  return 0
endfunction

function! s:lingr.get_rooms()
  return s:get('user/get_rooms', {'session' : self.session}).rooms
endfunction

function! s:lingr.room_show(rooms)
  return s:get('room/show', {
        \ 'session' : self.session,
        \ 'rooms'   : [a:rooms],
        \ }).rooms[0].messages
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

  let ret = s:get('room/subscribe', {
        \ 'session' : self.session,
        \ 'rooms' : rooms,
        \ })

  return ret.counter
endfunction

function! s:lingr.observe(counter, func)
  let cmd = 'curl -L -s -k -i "http://lingr.com:8080/api/event/observe?session=' 
        \ . self.session . '&counter=' . string(a:counter) . '"'
  call J6uil#thread#run(cmd, a:func)
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
