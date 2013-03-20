scriptencoding utf-8

if exists('b:current_syntax')
  finish
endif


setlocal conceallevel=2
setlocal concealcursor=nc

syntax match J6uil_appendix "\[\[.\{-1,}\]\]" contains=J6uil_appendix_block
syntax match J6uil_appendix_block /\[\[/ contained conceal
syntax match J6uil_appendix_block /\]\]/ contained conceal


hi def link J6uil_appendix        Comment

let b:current_syntax = 'J6uil'
