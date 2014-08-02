let s:save_cpo = &cpo
set cpo&vim

let s:Vital    = vital#of('J6uil')
let s:Web_HTTP = s:Vital.import('Web.HTTP')
let s:Web_JSON = s:Vital.import('Web.JSON')
unlet s:Vital

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

  call J6uil#thread#release()

  let ret = s:post('session/create', {
              \ 'app_key'  : '5xUaIa',
              \ 'user'     : self.username,
              \ 'password' : self.password,
              \ })

  if ret.status == 'error'
    throw 'code   : ' . ret.code . "\n" . 'detail : ' . ret.detail
  endif

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

  call self.login()
  return 0
endfunction

function! s:lingr.get_rooms()
  if exists('s:J6uil_room_cache')
    return s:J6uil_room_cache
  endif
  let rooms = s:get('user/get_rooms', {'session' : self.session}).rooms
  if exists('g:J6uil_user_define_rooms') && type(g:J6uil_user_define_rooms) == type([])
    for room in g:J6uil_user_define_rooms
      if index(rooms, room) == -1
        call add(rooms, room)
      endif
    endfor
  endif
  let s:J6uil_room_cache = rooms
  return rooms
endfunction

function! s:lingr.room_show(room)
  return s:get('room/show', {
        \ 'session' : self.session,
        \ 'rooms'   : [a:room],
        \ }).rooms[0]
endfunction

function! s:lingr.say(room, msg)
  let msg = iconv(a:msg, &encoding, 'utf8')

  if s:has_vimproc()
    call s:post_async('room/say', {
          \ 'session' : self.session,
          \ 'room'    : a:room,
          \ 'text'    : msg,
          \ },{})
    return 1
  end

  return s:get('room/say', {
        \ 'session' : self.session,
        \ 'room'    : a:room,
        \ 'text'    : msg,
        \ }).status == 'ok'
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

function! s:lingr.get_archives(room, before)
  let ret = s:get('room/get_archives', {
        \ 'session' : self.session,
        \ 'room'    : a:room,
        \ 'before'  : a:before,
        \ 'limit'   : 100,
        \ }).messages
  return ret
endfunction

function! s:get(url, param)
  let res = s:Web_HTTP.get(s:api_root . a:url, a:param)
  return s:Web_JSON.decode(res.content)
endfunction

function! s:post_async(url, query, headdata)
  let url      = s:api_root . a:url
  let postdata = a:query
  let headdata = a:headdata
  let method   = "POST"
  if type(postdata) == 4
    let postdatastr = s:Web_HTTP.encodeURI(postdata)
  else
    let postdatastr = postdata
  endif
  let command = 'curl -L -s -k -i -X '.method
  let quote = &shellxquote == '"' ?  "'" : '"'
  for key in keys(headdata)
    if has('win32')
      let command .= " -H " . quote . key . ": " . substitute(headdata[key], '"', '"""', 'g') . quote
    else
      let command .= " -H " . quote . key . ": " . headdata[key] . quote
	endif
  endfor
  let command .= " ".quote.url.quote
  let file = tempname()
  call writefile(split(postdatastr, "\n"), file, "b")
  " async post
  let cmd_line = command . " --data-binary @" . substitute(quote.file.quote, '\\', '/', "g")

  let s:vimproc = vimproc#pgroup_open(cmd_line)
  call s:vimproc.stdin.close()
  let s:result = ""

  augroup J6uil-async-receive
    execute "autocmd! CursorHold,CursorHoldI * call"
          \ "s:receive_vimproc_result('" . s:Web_JSON.encode({"file" : file})  . "')"
  augroup END
endfunction

function! s:receive_vimproc_result(param)
  if !has_key(s:, "vimproc")
    return
  endif

  let vimproc = s:vimproc

  try
    if !vimproc.stdout.eof
      let s:result .= vimproc.stdout.read(1000, 0)
    endif

    if !vimproc.stderr.eof
      let s:result .= vimproc.stderr.read(1000, 0)
    endif

    if !(vimproc.stdout.eof && vimproc.stderr.eof)
      return 0
    endif
  catch
    echom v:throwpoint
  endtry

  let param = s:Web_JSON.decode(a:param)

  call delete(param.file)

  "call function(a:handler)(s:result, a:param)

  augroup J6uil-async-receive
    autocmd!
  augroup END

  call vimproc.stdout.close()
  call vimproc.stderr.close()
  call vimproc.waitpid()
  unlet s:vimproc
  unlet s:result
endfunction




function! s:has_vimproc()
  if !exists('s:exists_vimproc')
    try
      call vimproc#version()
      let s:exists_vimproc = 1
    catch
      let s:exists_vimproc = 0
    endtry
  endif
  return s:exists_vimproc
endfunction

function! s:post(url, param)
  let res = s:Web_HTTP.post(s:api_root . a:url, a:param)
  return s:Web_JSON.decode(res.content)
endfunction


let &cpo = s:save_cpo
