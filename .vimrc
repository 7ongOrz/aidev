" 不兼容 Vi 的旧模式，使用 Vim 现代特性
set nocompatible

" 使用系统剪贴板
set clipboard=unnamed

" 显示行号
set number
" 显示相对行号（方便快速跳转，如 5j 跳转 5 行）
set relativenumber
" 显示当前光标位置
set ruler

" 禁用备份和交换文件（保持干净）
set nobackup
set noswapfile
set nowritebackup

" 语法高亮
syntax on

" 显示空白字符（制表符显示为 >-，行尾空格显示为 ·）
set list
set listchars=tab:>-,trail:·

" 用空格代替制表符
set expandtab
set tabstop=4
set shiftwidth=4

" 启用鼠标支持（包括滚动）
set mouse=a
