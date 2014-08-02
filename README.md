J6uil.vim
=====

yet another lingr.vim

![img](http://cdn-ak.f.st-hatena.com/images/fotolife/b/basyura/20130915/20130915114947.png)

![img](http://cdn-ak.f.st-hatena.com/images/fotolife/b/basyura/20130915/20130915114946.png)

License
-------

MIT License

Requires
--------

- [vimproc](https://github.com/Shougo/vimproc)


Settings
---------

    let g:J6uil_user     = 'your user name'
    let g:J6uil_password = 'your password'

    or

    let g:lingr_vim_user     = 'your user name'
    let g:lingr_vim_password = 'you password'

    let g:J6uil_display_offline  = 0
    let g:J6uil_display_online   = 0
    let g:J6uil_echo_presence    = 1
    let g:J6uil_display_icon     = 0
    let g:J6uil_display_interval = 0
    let g:J6uil_updatetime       = 1000
    let g:J6uil_multi_window     = 0

Usage
-----

subscribe

    :J6uil room

reconnect

    :J6uilReconnect

say

  - s on J6uil buffer in normal mode
  - &lt;CR&gt; in normal mode
  - &lt;C-CR&gt; in insert mode


Reference
---------

- [Vim で簡単に非同期処理を行うラッパを書いた](http://d.hatena.ne.jp/osyo-manga/20121010/1349795470)
