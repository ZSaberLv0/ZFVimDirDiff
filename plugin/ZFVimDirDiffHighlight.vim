
" ============================================================
function! ZF_DirDiffHL_resetHL_default()
    call ZF_DirDiffHL_resetHL_matchaddWithCursorLineHL()
endfunction
function! ZF_DirDiffHL_addHL_default(group, line)
    call ZF_DirDiffHL_addHL_matchaddWithCursorLineHL(a:group, a:line)
endfunction

" ============================================================
" use matchadd() and save/restore CursorLine highlight automatically
function! ZF_DirDiffHL_resetHL_matchaddWithCursorLineHL()
    call ZF_DirDiffHL_resetHL_matchadd()
    if !b:ZFDirDiff_isLeft
        return
    endif

    call s:restoreCursorLineHL()
    call s:saveCursorLineHL()

    highlight CursorLine gui=underline guibg=NONE guifg=NONE
    highlight CursorLine cterm=underline ctermbg=NONE ctermfg=NONE

    augroup ZF_DirDiffHL_CursorLine_augroup
        autocmd!
        autocmd BufDelete * call s:resetCursorLineHL()
    augroup END
endfunction
function! ZF_DirDiffHL_addHL_matchaddWithCursorLineHL(group, line)
    call ZF_DirDiffHL_addHL_matchadd(a:group, a:line)
endfunction
function! s:resetCursorLineHL()
    augroup ZF_DirDiffHL_CursorLine_augroup
        autocmd!
    augroup END
    call s:restoreCursorLineHL()
endfunction

function! s:saveCursorLineHL()
    redir => highlight
    silent hi CursorLine
    redir END
    if highlight =~ 'links to '
        let s:hl_link = matchstr(highlight, 'links to \zs\S*')
    elseif highlight =~ '\<cleared\>'
        let s:hl_link = 'NONE'
    else
        let s:hl_link = ''
        for substr in ['term', 'cterm', 'ctermfg', 'ctermbg',
                    \ 'gui', 'guifg', 'guibg', 'guisp']
            if highlight =~ substr . '='
                let s:hl_{substr} = matchstr(highlight,
                            \ substr . '=\S*')
            else
                let s:hl_{substr} = ''
            endif
        endfor
    endif
endfunction
function! s:restoreCursorLineHL()
    if !exists('s:hl_link')
        return
    endif
    hi clear CursorLine
    if s:hl_link == ''
        exe 'hi CursorLine' s:hl_term s:hl_cterm s:hl_ctermfg
                    \ s:hl_ctermbg s:hl_gui s:hl_guifg s:hl_guibg
                    \ s:hl_guisp
    elseif s:hl_link != 'NONE'
        exe 'hi link CursorLine' s:hl_link
    endif
    unlet s:hl_link
endfunction

" ============================================================
" use matchadd()
" * highlight can not be applied to entire line
function! ZF_DirDiffHL_resetHL_matchadd()
    call clearmatches()
endfunction

function! ZF_DirDiffHL_addHL_matchadd(group, line)
    if get(g:, 'ZF_DirDiffHL_addHL_matchadd_useExactHL', 1)
        let line = getline(a:line)
        if a:line >= b:ZFDirDiff_iLineOffset + 1 && a:line < len(t:ZFDirDiff_dataUIVisible) + b:ZFDirDiff_iLineOffset + 1
            let line = substitute(line, '/', '', 'g')
            let indent = matchstr(line, '^ *')
            call matchadd(a:group, ''
                        \   . '\%' . a:line . 'l'
                        \   . '\%>' . len(indent) . 'c'
                        \   . '\%<' . (len(line) + 1) . 'c'
                        \ )
        else
            call matchadd(a:group, '\%' . a:line . 'l')
        endif
    else
        if exists('*matchaddpos')
            call matchaddpos(a:group, [a:line])
        else
            call matchadd(a:group, '\%' . a:line . 'l')
        endif
    endif
endfunction

" ============================================================
" use sign-commands
" * current line would have no highlight
function! ZF_DirDiffHL_resetHL_sign()
    silent! execute 'sign unplace * buffer=' . bufnr('.')

    sign define ZFDirDiffHLSign_Title linehl=ZFDirDiffHL_Title
    sign define ZFDirDiffHLSign_Dir linehl=ZFDirDiffHL_Dir
    sign define ZFDirDiffHLSign_Same linehl=ZFDirDiffHL_Same
    sign define ZFDirDiffHLSign_Diff linehl=ZFDirDiffHL_Diff
    sign define ZFDirDiffHLSign_DirOnlyHere linehl=ZFDirDiffHL_DirOnlyHere
    sign define ZFDirDiffHLSign_DirOnlyThere linehl=ZFDirDiffHL_DirOnlyThere
    sign define ZFDirDiffHLSign_FileOnlyHere linehl=ZFDirDiffHL_FileOnlyHere
    sign define ZFDirDiffHLSign_FileOnlyThere linehl=ZFDirDiffHL_FileOnlyThere
    sign define ZFDirDiffHLSign_ConflictDir linehl=ZFDirDiffHL_ConflictDir
    sign define ZFDirDiffHLSign_ConflictFile linehl=ZFDirDiffHL_ConflictFile

    let b:ZFDirDiffHLSignIndex = 1
endfunction
function! ZF_DirDiffHL_addHL_sign(group, line)
    let cmd = 'sign place '
    let cmd .= b:ZFDirDiffHLSignIndex
    let cmd .= ' line=' . a:line
    let cmd .= ' name=' . substitute(a:group, 'ZFDirDiffHL_', 'ZFDirDiffHLSign_', '')
    let cmd .= ' buffer=' . bufnr('%')
    execute cmd
    let b:ZFDirDiffHLSignIndex += 1
endfunction

