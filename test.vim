
function MakeSign()
        call sign_define('testsign', {"text" : "T",})

        :execute "e newfile"
        normal! inewline
        normal! 10onewline
        " place at line 2
        call sign_place(0, 'testsigngroup', 'testsign', bufname(bufnr()), {'lnum':3, 'priority':12})
        normal! 3gg
endfun

" call MakeSign()
source tabs.vim
call InitializeTabWindows()
call MakeFloatingWindow()
normal! j
call MakeFloatingWindow()
normal! j
call MakeFloatingWindow()
call NextTab('down')
call QuitTab()
call PositionFloatingWindows()
