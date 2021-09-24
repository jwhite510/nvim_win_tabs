function! PositionFloatingWindows()
        echo g:windowtabs
        if has_key(g:windowtabs, win_getid())
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
                            \'focusable': 1} " disables focue with c-w-w
    let win = nvim_open_win(0, 0, opts)

    if !exists('g:windowtabs')
            let g:windowtabs = {}
    endif

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
