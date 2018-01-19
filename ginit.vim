" Put into ~/AppData/Local/nvim/ginit.vim

" Font & linespacing
GuiFont! Input:h9
" Does not work with negative numbers
" GuiLinespace -2
call rpcnotify(0, 'Gui', 'Linespace', 0)

