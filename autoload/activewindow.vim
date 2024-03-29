function activewindow#Toggle() abort
    let g:activewindow#enable = !g:activewindow#enable
    if g:activewindow#enable
        augroup ActiveWindow
            autocmd!
            autocmd WinEnter * call activewindow#set()
        augroup END
        call activewindow#set()
        echo 'ActiveWindow enabled'
    else
        autocmd! ActiveWindow
        call activewindow#restore()
        echo 'ActiveWindow disabled'
    endif
endfunction

function activewindow#set() abort
    for l:nr in range(1, winnr('$'))
        if s:Skip(l:nr) | continue | endif
        if l:nr == winnr()
            call setwinvar(l:nr, '&number', &g:number)
            call setwinvar(l:nr, '&relativenumber', &g:relativenumber)
            call setwinvar(l:nr, '&foldcolumn', &g:foldcolumn)
            if g:activewindow#cursorline
                call setwinvar(l:nr, '&cursorline', 1)
            endif
        else
            call setwinvar(l:nr, '&number', 0)
            call setwinvar(l:nr, '&relativenumber', 0)
            let l:pad = s:LineNumberWidth(l:nr)
            if getwinvar(l:nr, '&signcolumn') == 'number'
                let l:pad -= s:SignWidth(l:nr)
            endif
            call setwinvar(l:nr, '&foldcolumn', &g:foldcolumn + l:pad)
            if g:activewindow#cursorline
                call setwinvar(l:nr, '&cursorline', 0)
            endif
        endif
    endfor
endfunction

function activewindow#restore() abort
    for l:nr in range(1, winnr('$'))
        call setwinvar(l:nr, '&number', &g:number)
        call setwinvar(l:nr, '&relativenumber', &g:relativenumber)
        call setwinvar(l:nr, '&foldcolumn', &g:foldcolumn)
        call setwinvar(l:nr, '&cursorline', &g:cursorline)
    endfor
endfunction

function s:LineNumberWidth(winnr) abort
    if exists('*win_getid') && s:HasVersion(801,1987)
        let l:linenr=line('$', win_getid(a:winnr))
    else
        let l:current_winnr = winnr()
        let l:prev_winnr = winnr('#')
        execute 'noautocmd keepalt keepjumps '.a:winnr.'wincmd w'
        let l:linenr = line('$')
        execute 'noautocmd keepalt keepjumps'.l:prev_winnr.'wincmd w'
        execute 'noautocmd keepalt keepjumps'.l:current_winnr.'wincmd w'
    endif
    return max([&numberwidth, strlen(l:linenr)+1])
endfunction

function s:SignWidth(winnr) abort
    let l:signcolumn = getwinvar(a:winnr, '&signcolumn')
    if l:signcolumn == 'auto' || ( l:signcolumn == 'number' && a:winnr != winnr() )
        if exists('*sign_getplaced')
           let l:width = len(sign_getplaced(winbufnr(a:winnr),{'group':'*'})[0]['signs']) ? 2 : 0
        else
            let l:signlist = execute('sign place buffer='.winbufnr(a:winnr))
            let l:signlist = split(l:signlist, "\n")
            let l:width = len(l:signlist) > 2 ? 2 : 0
        endif
    elseif l:signcolumn == 'yes'
        let l:width = 2
    else
        let l:width = 0
    endif
    return l:width
endfunction

function s:Skip(winnr) abort
    return !empty(g:activewindow#skip) && bufname(winbufnr(a:winnr)) =~ join(g:activewindow#skip, '\|')
endfunction

function s:HasVersion(...) abort
    if has('nvim')
        return v:true
    endif

    if a:0 == 1
        return v:version >= a:1
    elseif a:0 == 2
        return v:version > a:1 || v:version == a:1 && has('patch'.string(a:2))
    else
        throw 'HasVersion: wrong number of inputs'
    endif
endfunction
