"
"
function! J6uil#cache_manager#new()
  return deepcopy(s:cache_manager)
endfunction

let s:cache_manager = {
      \  '_cache' : {},
      \  }

let s:cache = {
      \  'room'         : '',
      \  'messages'     : [],
      \  'members'      : [],
      \  'unread_count' : 0,
      \ }

"
"
function! s:cache_manager.get_cache(...)
  if a:0
    return self.get_cache(a:1)
  endif

  retur values(self._cache)
  
endfunction

"
"
function! s:cache_manager.get_unread_count(room)
  return self._get_cache(a:room).unread_count
endfunction

"
"
function! s:cache_manager.count_up_unread(room)
  let cache = self._get_cache(a:room)
  let cache.unread_count += 1
endfunction
"
"
function! s:cache_manager.cache_presence(room, presences)

  if type(a:presences) != 3
    let presences = [a:presences]
  else
    let presences = a:presences
  endif

  for presence in presences
    let cache = self._get_cache(a:room)

    let ev = {
      \ 'name'      : has_key(presence, 'name')      ? presence.name      : presence.nickname,
      \ 'is_online' : has_key(presence, 'is_online') ? presence.is_online : presence.status == 'online',
      \ 'is_owner'  : has_key(presence, 'is_owner')  ? presence.is_owner  : 0,
      \ }

    let flg = 0
    for member in cache.members
      if member.name == ev.name
        let member.is_online = ev.is_online
        let flg = 1
        break
      endif
    endfor
    if !flg
      call add(cache.members, ev)
    end
  endfor
endfunction

"
"
function! s:cache_manager.get_members(room)
  return self._get_cache(a:room).members
endfunction

"
"
function! s:cache_manager._get_cache(room)

  let room = a:room

  if !has_key(self._cache, room)
    let copied = deepcopy(s:cache)
    let copied.room = room
    let self._cache[room] = copied
  endif

  return self._cache[room]
endfunction
