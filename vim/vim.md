This is the overview for the Vim LFP talk. Everything we talked about is in
here, but you might need to spelunk on Google or vim help if you've forgotten
what something does.

A .vimrc with everything in this talk is in `vimrc_talk`.

My .vimrc is in `vimrc_kmowery`. Everything we talked about is in there, but it
has quite a bit more.

Movement
=======

Vim movement is its own special beast:

* hjkl
* $, ^
* fF / tT / ; / ,
* b, e, w
* (), {}
* ctrl-d, ctrl-u, ctrl-e, ctrl-y
* ctrl-f, ctrl-b
* tab
* a, i, A, I
* g

Nouns and Verbs
===============

Here are some verbs:

* c, d
* y
* r

Here are some nouns:

* w: word
* s: sentence
* p: paragraph
* b: block
* t: HTML/XML tag
* /: regex!
* ', ": strings!
* (), [], {}: brackets!

Here are some modifiers:

* a: a (one thing)
* i: inside (another thing)
* t: to (exclusive)
* f: to (inclusive)

`g`lobal is good times:

* :g/^/m0
* :g/REGEX/d


PlugIns Intro
============
  Vundle Setup

```
$ git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
```


And in the vimrc:

```
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

Plugin 'vim-scripts/camelcasemotion'

call vundle#end()            " required
filetype plugin indent on    " required
```

Movement Redux
==============
CamelCaseMotion

```
Plugin 'vim-scripts/camelcasemotion'
```

And to remember how to use it:

```
" Use CamelCaseMotion for all movement commands
map <silent> w <Plug>CamelCaseMotion_w
map <silent> b <Plug>CamelCaseMotion_b
map <silent> e <Plug>CamelCaseMotion_e
sunmap w
sunmap b
sunmap e
omap <silent> iw <Plug>CamelCaseMotion_iw
xmap <silent> iw <Plug>CamelCaseMotion_iw
omap <silent> ib <Plug>CamelCaseMotion_ib
xmap <silent> ib <Plug>CamelCaseMotion_ib
omap <silent> ie <Plug>CamelCaseMotion_ie
xmap <silent> ie <Plug>CamelCaseMotion_ie
```

Rad numbers:

```
Plugin 'myusuf3/numbers.vim'
```

Visual Mode
===========
Visual mode is rad:

*  shift+v
*  ctrl+v
*  copy/paste blocks

Shove through command line program:

```
!sort
```

Sometimes you screw up and open a root or read-only file?

Force save:

```
w!
```

Put this in your vimrc:

```
cmap w!! w !sudo tee % >/dev/null
```

And then you can:

```
w!!
```
Leader Keys
===========

```
" use C-; to go backward after an [ftFT]
noremap z ,
let mapleader=","  " change the mapleader from \ to ,
```


,W
--
Whitespace at the end of lines should be shot. Use ,W to kill it.
 
```
" ,W - strip all trailing whitespace in file
nnoremap <leader>W :%s/\s\+$//<cr>:let @/=''<CR>0
```

,p
--
Line wrapping a paragraph can be done with `gqap` (`gq` verb, `a` modifier, `p`
paragraph!). Switch to ,p:

```
" Format a paragraph
nnoremap <leader>p gqap
```


Splits and Tabs
========
Tabs and splits are essential, so let's give ourselves a shortcut:

```
" ,w - vertical split and move over
nnoremap <leader>w <C-w>v<C-w>l

" ,q - split tabs
nnoremap <leader>q :tab split<CR>
```

Vim should open in tabs by default. Add this to your shell:
 
```
alias vim="vim -p"
```

(Bonus aside: vim comes with a rad mode where it copies less, plus syntax
highlighting and stuff. To use, add to shell:

```
[ -e '/usr/share/vim/vim73/macros/less.vim' ] && \
alias vless='vim -u /usr/share/vim/vim73/macros/less.vim'
```

For extra niceness, resize splits when vim is resized:

```
" Resize splits when the window is resized
au VimResized * exe "normal! \<c-w>="
```


Updated Files
=============

To make vim notice that files have changed:

```
autocmd CursorHold * checktime
```

But then you'll confuse gvim and MacVim, which do this by default, so add some
guards:

```
if !has("gui_running")
  au CursorHold * checktime
endif
```

Plugin: vim-session
===================

vim-session is rad. Let's talk about it.

```
Plugin 'xolox/vim-misc'
Plugin 'xolox/vim-session'
```

And customize it so it stops bugging us:

```
" Set vim-session all up
let g:session_default_overwrite = 1   " overwrite default session; don't bug me about it
let g:session_autoload = 'no'         " never autoload a session
let g:session_autosave = 'yes'        " autosave on quit
let g:session_autosave_periodic = 60  " minutes
let g:session_persist_globals = []
  call add(g:session_persist_globals, '&tabstop')
  call add(g:session_persist_globals, '&softtabstop')
  call add(g:session_persist_globals, '&shiftwidth')
  "call add(g:session_persist_globals, 'noexpandtab')
let g:session_command_aliases = 1     " add aliases that start with Session*
```


Plugin: gundo
=============
Vim's undo is AMAZING, but most people just use `u` and `ctrl-R`. There's
actually an entire undo Tree consisting of everything you've ever done. Use
`gundo`:

```
Plugin 'sjl/gundo.vim'
```

And bind it to `,u`:

```
nnoremap <leader>u :GundoToggle<cr>
```

I've copied text out of 2 hours ago. SO GREAT.

But it goes away when you restart vim and we just talked about vim-session
so....

```
set undodir=~/.vim/undo/ " set the undo directory
set undofile            " persist undo across vim sessions
```

Remember to make the directory!

```
$ mkdir ~/.vim/undo
```

Plugin: ctrl-p
==============
ctrl-p is a great plugin for "fuzzy open"-ing files in your directory. I don't
use it much, but when I do it's pretty rad.

```
Plugin 'kien/ctrlp.vim'
```

But we already bound ctrl-p! `D:`

```
" customize ctrlp
let g:ctrlp_map = '<c-o>'
let g:ctrlp_max_files = 0
let g:ctrlp_max_depth = 64
let g:ctrlp_custom_ignore = '\v[\/]\.(git|hg|svn)$'
" ctrp-p directory is nearest parent repo, or directory of current file
let g:ctrlp_working_path_mode = 'ra'
```

Plugin: tagbar
==============

tagbar is useful when navigating large files:

```
Plugin 'majutsushi/tagbar'
```

And to make it useful:

```
" TagBar
nnoremap <silent> <leader>t :TagbarToggle<CR>
```

Plugin: tabular
===============

Sometimes you just gotta align some symbols. Use Tabular:

```
Plugin 'godlygeek/tabular'
```

And again because I can never remember how to use the thing:

```
" Tabularize
nmap <Leader>a= :Tabularize /=<CR>
vmap <Leader>a= :Tabularize /=<CR>
nmap <Leader>a: :Tabularize /:<CR>
vmap <Leader>a: :Tabularize /:<CR>
nmap <Leader>a:: :Tabularize /:\zs<CR>
vmap <Leader>a:: :Tabularize /:\zs<CR>
nmap <Leader>a, :Tabularize /,<CR>
vmap <Leader>a, :Tabularize /,<CR>
nmap <Leader>a<Bslash> :Tabularize /\<CR>
vmap <Leader>a<Bslash> :Tabularize /\<CR>
nmap <leader>a/ :Tabularize //<cr>
vmap <leader>a/ :Tabularize //<cr>
nmap <leader>a<Bar> :Tabularize /<Bar><cr>
vmap <leader>a<Bar> :Tabularize /<Bar><cr>
nmap <Leader>a[ :Tabularize /[<CR>
vmap <Leader>a[ :Tabularize /[<CR>
nmap <Leader>a] :Tabularize /]<CR>
vmap <Leader>a] :Tabularize /]<CR>
```

Then, `,a=` will align all the equal signs in the visual region or paragraph.

Macros
======
Suuuuuper quick macro tutorial:

In normal mode, press `q` and then a letter to start recording. Do Things, then press `q` in
normal mode again to stop recording. Then, you can rerun those commands with
`@`+letter, and then again with `@@` or `.`.


Things to Wedge In
==================
* Paste registers
* Mark/recall
* ctrl-a, ctrl-x

