""""""""""""NERDTree CONFIG""""""""""""
autocmd vimenter * NERDTree
nmap <silent> <c-n> :NERDTreeToggle<CR>
let NERDTreeMinimalUI = 1
let g:NERDTreeWinSize = 30
let NERDTreeHighlightCursorline = 1
noremap <silent> <C-h> <C-w>h
nnoremap <silent> <C-l> <C-w>l
nnoremap <silent> <C-k> <C-w>k
nnoremap <silent> <C-j> <C-w>j

""""""""""""GENERAL CONFIG"""""""""""""
syntax on

set number
set hlsearch
set autoread
set updatetime=100
set colorcolumn=145
highlight ColorColumn ctermbg=darkgray
colorscheme torte
autocmd BufNewFile,BufRead *.md set filetype=markdown
"list tab as > and -"
"set list
"set listchars=tab:>-
""highlight trailing whitespace"
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()

"""""""""""FOLD CONFIG"""""""""""""""
set foldmethod=indent
set foldlevel=99
nnoremap <space> za

"""""""""""PEP 8 INDENTATION"""""""""""
au BufNewFile,BufRead *.py
    \ set tabstop=4 |
    \ set softtabstop=4 |
    \ set shiftwidth=4 |
    "\ set textwidth=79 |
    "    \ set expandtab |
    "        \ set autoindent |
    "            \ set fileformat=unix
    "            "" Flag extra whitespace
:highlight BadWhitespace ctermfg=16 ctermbg=9 guifg=#000000 guibg=#F8F8F0
au BufRead,BufNewFile *.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/

"""""""""""GIT-GUTTER CONFIG"""""""""""
let g:gitgutter_diff_base = 'HEAD'

"""""""""""Exit Highlighter"""""""""""
nnoremap <esc> :noh<return><esc>


"""""""""""IRGNORE TEMP FILE"""""""""""
set noswapfile
set nobackup
set nowritebackup
