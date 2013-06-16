let s:save_cpo = &cpo
set cpo&vim

""""""""""""""""""""""""
"   local  functions   "
""""""""""""""""""""""""

function! s:set(key, default)
  if !has_key(g:, a:key)  
    let g:[a:key] = a:default
  endif
endfunction

function! s:start(...)
  let room = a:0 ? a:1 : ''
  call J6uil#subscribe(room)
endfunction

""""""""""""""""""""""""
"       variables      "
""""""""""""""""""""""""
call s:set('J6uil_config_dir'        , expand('~/.J6uil'))
call s:set('J6uil_insert_offline'    , 0)
call s:set('J6uil_insert_online'     , 0)
call s:set('J6uil_echo_presence'     , 1)
call s:set('J6uil_display_icon'      , 0)
call s:set('J6uil_debug_mode'        , 0)
call s:set('J6uil_updatetime'        , 1000)
call s:set('J6uil_open_buffer_cmd'   , 'edit!')
call s:set('J6uil_display_separator' , 1)
call s:set('J6uil_empty_separator'   , 0)
call s:set('J6uil_nickname_length'   , 12)
call s:set('J6uil_no_default_keymappings', 0)
call s:set('J6uil_align_message', 1)

""""""""""""""""""""""""
"       initialize     "
""""""""""""""""""""""""

if !isdirectory(g:J6uil_config_dir)
  call mkdir(g:J6uil_config_dir . "/icon", 'p')
endif

""""""""""""""""""""""""
"       commands       "
""""""""""""""""""""""""

command! -nargs=? J6uil call s:start(<f-args>)

command! -nargs=0 J6uilReconnect  call J6uil#reconnect()

command! -nargs=0 J6uilDisconnect call J6uil#disconnect()

""""""""""""""""""""""""
"       key maps       "
""""""""""""""""""""""""
"
nnoremap <silent> <Plug>(J6uil_open_say_buffer)   :<C-u>call J6uil#say#open(J6uil#buffer#current_room())<CR>
"
nnoremap <silent> <Plug>(J6uil_reconnect)         :<C-u>J6uilReconnect<CR>
"
nnoremap <silent> <Plug>(J6uil_disconnect)        :<C-u>J6uilDisconnect<CR>
"
nnoremap <silent> <Plug>(J6uil_unite_rooms)       :<C-u>Unite J6uil/rooms -buffer-name=J6uil_rooms<CR>
"
nnoremap <silent> <Plug>(J6uil_unite_members)     :<C-u>Unite J6uil/members -buffer-name=J6uil_members<CR>
"
nnoremap <silent> <Plug>(J6uil_action_enter)      :<C-u>call J6uil#action('enter')<CR>
"
nnoremap <silent> <Plug>(J6uil_action_open_links) :<C-u>call J6uil#action('open_links')<CR>








let &cpo = s:save_cpo
