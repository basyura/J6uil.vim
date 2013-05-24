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
  return s:get('user/get_rooms', {'session' : self.session}).rooms
endfunction

function! s:lingr.room_show(room)
  return s:get('room/show', {
        \ 'session' : self.session,
        \ 'rooms'   : [a:room],
        \ }).rooms[0]
endfunction

function! s:lingr.say(room, msg)
  if s:has_vimproc()
    call s:post_async('room/say', {
          \ 'session' : self.session,
          \ 'room'    : a:room,
          \ 'text'    : a:msg,
          \ },{})
    return 1
  end

  return s:get('room/say', {
        \ 'session' : self.session,
        \ 'room'    : a:room,
        \ 'text'    : a:msg,
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
        \ }).messages
  return ret
endfunction

function! s:get(url, param)
  let res = webapi#http#get(s:api_root . a:url, a:param)
  return webapi#json#decode(res.content)
endfunction

function! s:post_async(url, query, headdata)
  let url      = s:api_root . a:url
  let postdata = a:query
  let headdata = a:headdata
  let method   = "POST"
  if type(postdata) == 4
    let postdatastr = webapi#http#encodeURI(postdata)
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
          \ "s:receive_vimproc_result('" . webapi#json#encode({"file" : file})  . "')"
  augroup END
endfunction

function! s:receive_vimproc_result(param)
  if !has_key(s:, "vimproc")
    return
  endif

  let vimproc = s:vimproc

  try
    if !vimproc.stdout.eof
      let s:result .= vimproc.stdout.read()
    endif

    if !vimproc.stderr.eof
      let s:result .= vimproc.stderr.read()
    endif

    if !(vimproc.stdout.eof && vimproc.stderr.eof)
      return 0
    endif
  catch
    echom v:throwpoint
  endtry

  let param = webapi#json#decode(a:param)

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
  let res = webapi#http#post(s:api_root . a:url, a:param)
  return webapi#json#decode(res.content)
endfunction


let &cpo = s:save_cpo
