" Minimal, sane Vim config for macOS

set nocompatible
set encoding=utf-8

" UI
set number
set ruler
set showcmd
set mouse=a
if has('termguicolors')
  set termguicolors
endif

" Search
set ignorecase
set smartcase
set incsearch
set hlsearch

" Indentation
set expandtab
set shiftwidth=2
set softtabstop=2
set tabstop=2
set smartindent

" Files
set hidden
set nowrap
set backspace=indent,eol,start
set confirm

" Clipboard (only if supported)
if has('clipboard')
  set clipboard^=unnamed,unnamedplus
endif

" Language / plugins
syntax on
filetype plugin indent on

" Keep it predictable
set updatetime=300
set shortmess+=c

