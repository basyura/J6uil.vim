scriptencoding utf-8

if exists('b:current_syntax')
  finish
endif


setlocal conceallevel=2
setlocal concealcursor=nc

syntax match J6uil_time " \d\d/\d\d \d\d:\d\d$" contains=J6uil_time
syntax match J6uil_appendix "\[\[.\{-1,}\]\]" contains=J6uil_appendix_block
syntax match J6uil_appendix_block /\[\[/ contained conceal
syntax match J6uil_appendix_block /\]\]/ contained conceal
syntax match J6uil_link "https\?://\%([0-9A-Za-z.-]\+\|\[[0-9A-Fa-f:]\+\]\)\%(:[0-9]\+\)\?\%(/[^[:blank:]\"<>\\^`{|}]\+\)\?"
syntax match J6uil_separator       "^-\+$"

syntax region J6uil_sudden_death start="＿人人" end="ＹＹ￣" contains=J6uil_sudden_death

syntax match J6uil_quotation " : \zs>.*\ze\[\{-}" contains=J6uil_appendix
syntax match J6uil_quotation "^\s\+\zs>.*\ze\[\{-}" contains=J6uil_appendix
syntax match J6uil_quotation " : \zs＞.*\ze\[\{-}" contains=J6uil_appendix
syntax match J6uil_quotation "^\s\+\zs＞.*\ze\[\{-}" contains=J6uil_appendix



hi def link J6uil_time         Comment
hi def link J6uil_appendix     Comment
hi def link J6uil_link         Underlined
hi def link J6uil_separator    Ignore
hi def link J6uil_quotation    Comment
hi def link J6uil_sudden_death Error

let b:current_syntax = 'J6uil'
