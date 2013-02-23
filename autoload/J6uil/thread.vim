let s:save_cpo = &cpo
set cpo&vim

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


let &cpo = s:save_cpo
