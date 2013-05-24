let s:save_cpo = &cpo
set cpo&vim

function! J6uil#thread#run(cmd, ...)
    let thread = call("s:make_thread", [a:cmd] + a:000)
    call thread.run()
    return thread
endfunction

function! J6uil#thread#is_exists()
    return !empty(g:J6uil_thread_list)
endfunction

function! J6uil#thread#count()
    return len(g:J6uil_thread_list)
endfunction

function! J6uil#thread#has_many()
    return !empty(g:J6uil_thread_list) && len(g:J6uil_thread_list) > 1
endfunction

function! s:release(threads)
    for thread in a:threads
      "if g:J6uil_debug_mode | echomsg 'J6uil killed ' . thread.vimproc.pid | endif
      call vimproc#kill(thread.vimproc.pid, 9)
    endfor
endfunction

function! J6uil#thread#release()
    call s:release(values(g:J6uil_thread_list))
endfunction

if has_key(g:, "J6uil_thread_list")
    call s:release(values(g:J6uil_thread_list))
endif

" for reload
let g:J6uil_thread_list = {}

let g:J6uil_thread_counter = 0

augroup J6uil-thread
    autocmd!
    autocmd! CursorHold,CursorHoldI * call s:update(values(g:J6uil_thread_list))
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
    let g:J6uil_thread_list[g:J6uil_thread_counter] = a:thread
    let a:thread.id = g:J6uil_thread_counter
    let g:J6uil_thread_counter += 1
endfunction


function! s:thread_release(thread)
    unlet g:J6uil_thread_list[a:thread.id]
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



let &cpo = s:save_cpo
