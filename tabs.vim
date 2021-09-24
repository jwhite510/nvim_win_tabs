function! PositionFloatingWindows()
        " echo g:windowtabs
        if has_key(g:windowtabs, win_getid())
                " position the tabs
                for win in g:windowtabs[win_getid()]
                        let winwidth = winwidth(0)
                        call nvim_win_set_config(win, { 'relative':'win',
                                                \'row':0, 'col':winwidth })
                endfor
        endif

endfun

function! MakeFloatingWindow()
    let winwidth = winwidth(0)
    let opts = {'relative': 'win', 'width': 10, 'height': 10,
                            \'col': winwidth, 'row': 0,
                            \ 'anchor': 'NE',
                            \ 'border':"single",
                            \ 'zindex': 1,
                            \'focusable': 0} " disables focue with c-w-w
    let win = nvim_open_win(0, 0, opts)

    if !exists('g:windowtabs')
            let g:windowtabs = {}
    endif

    " create list of floating windows for this window if it doesn't exist
    if !exists(has_key(g:windowtabs, win_getid()))
        let g:windowtabs[win_getid()] = []
    endif
    let g:windowtabs[win_getid()] += [win]

    augroup windowtabsautocmds
            autocmd!
    augroup END
    :augroup windowtabsautocmds | au CursorHold *  call PositionFloatingWindows()

    " if !exists('g:windowtabs_autocmd_defined')
    "         let g:windowtabs_autocmd_defined = 1
    "         :augroup windowtabsautocmds | au CursorHold *  call PositionFloatingWindows()
    " endif

    " set the location of the window

endfun

function! SwapWithFloatingWindow()
        " select the floating window
        if has_key(g:windowtabs, win_getid())
                " set this window to the active window
                let buf1 = bufnr()
                :execute "mkview 8"

                " activate the tab window
                call nvim_set_current_win(g:windowtabs[win_getid()][0])
                " get the current view
                :execute ":mkview 9"
                let buf2 = bufnr()

                :execute ":b ".buf1
                :execute ":loadview 8"
                wincmd p
                :execute ":b ".buf2
                :execute ":loadview 9"
        endif
endfun
