
if exists('g:autoload_nvimtabs')
    finish
endif

let g:autoload_nvimtabs = 1

" define sign
" list the currently placed signs:
" :sign place group=tabwin_top_marker_group

call sign_define('tabwin_top_marker', {"text" : "",})

function! NvimTabs#UpdateTabInfo(window)
    " count all the tab views present in this window
    if has_key(g:windowtabs, a:window)
        let l:tabbuffercontents = []

        let i = 0
        while i <= len(g:windowtabs[win_getid()]['views'])
            if i == g:windowtabs[win_getid()]['tabdisplay']['index']
                let l:buffer_name = bufname(getwininfo(win_getid())[0]['bufnr'])
                let l:lnumcur = getcurpos()[1]
                let l:tabbuffercontents += ["*".fnamemodify(l:buffer_name.":".l:lnumcur, ":t")]
            endif
            if i < len(g:windowtabs[win_getid()]['views'])
                let win = g:windowtabs[win_getid()]['views'][i]

                let l:buffer_name = bufname(getwininfo(win['win'])[0]['bufnr'])
                " switch to window and check line number
                call nvim_set_current_win(win['win'])
                let l:lnumcur = getcurpos()[1]
                wincmd p
                " get line number also
                let l:tabbuffercontents += [" ".fnamemodify(l:buffer_name.":".l:lnumcur, ":t")]
            endif

            let i = i + 1
        endwhile

        for win in g:windowtabs[win_getid()]['views']
        endfor
        call nvim_buf_set_lines(g:windowtabs[a:window]['tabdisplay']['buf'],
                    \0, -1, v:true, l:tabbuffercontents)
    endif
endfun

function! NvimTabs#PositionFloatingWindows()
        " echo g:windowtabs
        if has_key(g:windowtabs, win_getid())
                " position the tabs
                call UpdateTabInfo(win_getid())
                let l:winwidth = winwidth(0)
                for win in g:windowtabs[win_getid()]['views']
                        call nvim_win_set_config(win['win'], { 'relative':'win',
                                                \'row':0, 'col':l:winwidth })
                endfor
                call nvim_win_set_config(g:windowtabs[win_getid()]['tabdisplay']['win'], { 'relative':'win',
                                        \'row':0, 'col':l:winwidth })


        endif

endfun

function NvimTabs#InsertView()
        " get the top line and cursor line
	let l:line_num = getcurpos()[1]
        let l:topline = getwininfo(win_getid())[0]['topline']
        " create a sign at the top line

        let g:winSignId = g:winSignId + 1
        let l:thisSignId = sign_place(g:winSignId, 'tabwin_top_marker_group', 'tabwin_top_marker', bufname(bufnr()), {'lnum':l:topline, 'priority':12})

        return { 'line_num': l:line_num, 'topline': l:thisSignId }
endfun

function NvimTabs#QuitWindow()
    let chwinid = win_getid()
    if has_key(g:windowtabs, chwinid)
        while has_key(g:windowtabs, chwinid)
            call QuitTab()
        endwhile
    endif
    " echom "quit window autocmd called"
    " if this is called, then clean up all the windows that were created from
endfun

function! NvimTabs#InitializeTabWindows()

    if !exists('g:windowtabs')
            let g:winSignId = 0
            let g:windowtabs = {}
    endif

    augroup windowtabsautocmds
            autocmd!
    augroup END
    :augroup windowtabsautocmds | au CursorHold *  call PositionFloatingWindows()
    :augroup windowtabsautocmds | au QuitPre *  call QuitWindow()

endfun

function! NvimTabs#MakeFloatingWindow()
    let l:startview = InsertView()
    let l:winwidth = winwidth(0)
    let l:opts = {'relative': 'win', 'width': 1, 'height': 1,
                            \'col': l:winwidth, 'row': 0,
                            \ 'anchor': 'NE',
                            \ 'zindex': 1,
                            \ 'style': 'minimal',
                            \'focusable': 0} " disables focue with c-w-w
    let l:win = nvim_open_win(0, 0, l:opts)

    " create list of floating windows for this window if it doesn't exist
    if !(has_key(g:windowtabs, win_getid()))

        let tabdrawbuf = nvim_create_buf(v:false, v:true)
        call nvim_buf_set_lines(tabdrawbuf, 0, -1, v:true, ["test", "text"])

        let tabdrawopts = {'relative': 'win', 'width': 20, 'height': 15, 'col': l:winwidth,
            \ 'row': 0, 'anchor': 'NE', 'style': 'minimal'}
        let tabdrawwin = nvim_open_win(tabdrawbuf, 0, tabdrawopts)
        " optional: change highlight, otherwise Pmenu is used
        " call nvim_win_set_option(tabdrawwin, 'winhl', 'Normal:MyHighlight')
        let g:windowtabs[win_getid()] = {'views':[], 'tabdisplay':{'win':tabdrawwin, 'buf':tabdrawbuf, 'index':0}}
        " create tab view window
    endif

    let g:windowtabs[win_getid()]['views'] += [{ 'win':l:win, 'view':l:startview }]
    call UpdateTabInfo(win_getid())

endfun

function! NvimTabs#SwapWithFloatingWindow(index)
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

                " update index
                let curindex = g:windowtabs[l:ui_window_id]['tabdisplay']['index']
                " echom "curindex: ".curindex
                " echom "a:index: ".a:index
                let newindex = (curindex == a:index) ? a:index + 1 : a:index
                " echom "newindex: ".newindex
                let g:windowtabs[l:ui_window_id]['tabdisplay']['index'] = newindex

                call UpdateTabInfo(l:ui_window_id)
        endif
endfun

function! NvimTabs#NextTab(direction)
    if has_key(g:windowtabs, win_getid())
        " get the current index
        let curindex = g:windowtabs[win_getid()]['tabdisplay']['index']
        " get the current length
        let curlength = len(g:windowtabs[win_getid()]['views'])
        if and(a:direction == 'up', curindex > 0)
            call SwapWithFloatingWindow(curindex - 1)
        elseif and(a:direction == 'down', curindex < curlength)
            call SwapWithFloatingWindow(curindex)
        endif

    endif
endfun

function! NvimTabs#QuitTab()
    " delete one (win) tab
    " get the current index
    let curindex = g:windowtabs[win_getid()]['tabdisplay']['index']
    let deleteindex = ( curindex == 0 ) ? curindex : curindex - 1

    let lastwin = win_getid()
    " set the view to the window that is about to be deleted
    call nvim_set_current_win(g:windowtabs[win_getid()]['views'][deleteindex]['win'])
    let l:bufnum = bufnr()
    :execute ":mkview 9"
    call nvim_set_current_win(lastwin)
    :execute ":b ".l:bufnum
    :execute ":loadview 9"
    let l:newvuew = g:windowtabs[win_getid()]['views'][deleteindex]['view']
    call sign_jump(l:newvuew['topline'], 'tabwin_top_marker_group','')
    call sign_unplace('tabwin_top_marker_group', { 'id':l:newvuew['topline'] })

    " close the window
    call nvim_set_current_win(g:windowtabs[win_getid()]['views'][deleteindex]['win'])
    " quit the window
    :execute ":q"
    call nvim_set_current_win(lastwin)
    " wincmd p
    "
    call remove(g:windowtabs[win_getid()]['views'], deleteindex)
    " echom g:windowtabs

    " set new index
    let g:windowtabs[win_getid()]['tabdisplay']['index'] = deleteindex

    " remove the marker

    if len(g:windowtabs[win_getid()]['views'] ) == 0
        " remove the tabs window
        call nvim_set_current_win(g:windowtabs[win_getid()]['tabdisplay']['win'])
        :execute ":bd"
        call nvim_set_current_win(lastwin)
        " delete key from dictionary
        unlet g:windowtabs[win_getid()]
    endif

    " remove from the list
    call UpdateTabInfo(win_getid())

    " set buffer to next available
endfun

call NvimTabs#InitializeTabWindows()

command! nvim_tabs_newtab call NvimTabs#MakeFloatingWindow()
command! nvim_tabs_closetab call NvimTabs#QuitTab()
command! nvim_tabs_tabdown call NvimTabs#NextTab('down')
command! nvim_tabs_tabup call NvimTabs#NextTab('up')
