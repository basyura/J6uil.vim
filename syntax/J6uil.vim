scriptencoding utf-8

if exists('b:current_syntax')
  finish
endif


setlocal conceallevel=2
setlocal concealcursor=nc

syntax match J6uil_appendix "\[\[.\{-1,}\]\]" contains=J6uil_appendix_block
syntax match J6uil_appendix_block /\[\[/ contained conceal
syntax match J6uil_appendix_block /\]\]/ contained conceal
syntax match J6uil_link "https\?://[0-9A-Za-z_#?~=\-+%\.\/:&!]\+"
syntax match J6uil_separator       "^-\+$"

syntax match J6uil_quotation " : \zs>.*\ze"
syntax match J6uil_quotation "^\s\+\zs>.*\ze"

hi def link J6uil_appendix   Comment
hi def link J6uil_link       Underlined
hi def link J6uil_separator  Ignore
hi def link J6uil_quotation  Comment

let b:current_syntax = 'J6uil'
