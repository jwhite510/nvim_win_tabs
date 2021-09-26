" define sign

call sign_define('tabwin_top_marker', {"text" : "w",})

function! UpdateTabInfo(window)
    " count all the tab views present in this window
    if has_key(g:windowtabs, a:window)
        let tabbuffercontents = []
        for win in g:windowtabs[win_getid()]['views']
            " echom bufname(getwininfo(win['win'])[0]['bufnr'])
            let l:buffer_name = bufname(getwininfo(win['win'])[0]['bufnr'])
            " switch to window and check line number
            call nvim_set_current_win(win['win'])
            let l:lnumcur = getcurpos()[1]
            wincmd p
            " get line number also
            let l:tabbuffercontents += [fnamemodify(l:buffer_name.":".l:lnumcur, ":t")]
        endfor
        call nvim_buf_set_lines(g:windowtabs[a:window]['tabdisplay']['buf'],
                    \0, -1, v:true, l:tabbuffercontents)
    endif
endfun

function! PositionFloatingWindows()
        " echo g:windowtabs
        if has_key(g:windowtabs, win_getid())
                " position the tabs
                for win in g:windowtabs[win_getid()]['views']
                        let l:winwidth = winwidth(0)
                        call nvim_win_set_config(win['win'], { 'relative':'win',
                                                \'row':0, 'col':l:winwidth })
                endfor
                call nvim_win_set_config(g:windowtabs[win_getid()]['tabdisplay']['win'], { 'relative':'win',
                                        \'row':0, 'col':l:winwidth })


        endif

endfun

function InsertView()
        " get the top line and cursor line
	let l:line_num = getcurpos()[1]
        let l:topline = getwininfo(win_getid())[0]['topline']
        " create a sign at the top line

        let g:winSignId = g:winSignId + 1
        let l:thisSignId = sign_place(g:winSignId, 'tabwin_top_marker_group', 'tabwin_top_marker', bufname(bufnr()), {'lnum':l:topline, 'priority':12})

        return { 'line_num': l:line_num, 'topline': l:thisSignId }
endfun

function! InitializeTabWindows()

    if !exists('g:windowtabs')
            let g:winSignId = 0
            let g:windowtabs = {}
    endif

    augroup windowtabsautocmds
            autocmd!
    augroup END
    :augroup windowtabsautocmds | au CursorHold *  call PositionFloatingWindows()

endfun

function! MakeFloatingWindow()
    let l:startview = InsertView()
    let l:winwidth = winwidth(0)
    let l:opts = {'relative': 'win', 'width': 30, 'height': 20,
                            \'col': l:winwidth, 'row': 0,
                            \ 'anchor': 'NE',
                            \ 'border':"single",
                            \ 'zindex': 1,
                            \'focusable': 0} " disables focue with c-w-w
    let l:win = nvim_open_win(0, 0, l:opts)

    " create list of floating windows for this window if it doesn't exist
    if !(has_key(g:windowtabs, win_getid()))

        let tabdrawbuf = nvim_create_buf(v:false, v:true)
        call nvim_buf_set_lines(tabdrawbuf, 0, -1, v:true, ["test", "text"])

        let tabdrawopts = {'relative': 'win', 'width': 30, 'height': 20, 'col': l:winwidth,
            \ 'row': 0, 'anchor': 'NE', 'style': 'minimal'}
        let tabdrawwin = nvim_open_win(tabdrawbuf, 0, tabdrawopts)
        " optional: change highlight, otherwise Pmenu is used
        " call nvim_win_set_option(tabdrawwin, 'winhl', 'Normal:MyHighlight')
        let g:windowtabs[win_getid()] = {'views':[], 'tabdisplay':{'win':tabdrawwin, 'buf':tabdrawbuf}}
        " create tab view window
    endif

    let g:windowtabs[win_getid()]['views'] += [{ 'win':l:win, 'view':l:startview }]
    call UpdateTabInfo(win_getid())

endfun

function! SwapWithFloatingWindow(index)
        " select the floating window
        if has_key(g:windowtabs, win_getid())
                let l:ui_window_id = win_getid()
                " set this window to the active window
                let l:buf1 = bufnr()
                :execute "mkview 8"
                let l:curview = InsertView()

                " activate the tab window
                call nvim_set_current_win(g:windowtabs[l:ui_window_id]['views'][a:index]['win'])
                " get the current view
                :execute ":mkview 9"
                let l:newlinenum = getcurpos()[1]
                let l:buf2 = bufnr()
                let l:newvuew = g:windowtabs[l:ui_window_id]['views'][a:index]['view']

                :execute ":b ".l:buf1
                :execute ":loadview 8"
                let g:windowtabs[l:ui_window_id]['views'][a:index]['view'] = l:curview

                wincmd p
                :execute ":b ".l:buf2
                :execute ":loadview 9"
                call sign_jump(l:newvuew['topline'], 'tabwin_top_marker_group','')
                call sign_unplace('tabwin_top_marker_group', { 'id':l:newvuew['topline'] })
                " remove the sign
                :execute "normal! zt"
                :execute "normal! ".l:newlinenum."gg"
                call UpdateTabInfo(l:ui_window_id)
        endif
endfun
