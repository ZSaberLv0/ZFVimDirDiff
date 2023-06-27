
command! -nargs=* -complete=file ZFDirDiffMark :call ZFDirDiffMark(<q-args>)
command! -nargs=0 ZFDirDiffUnmark :call ZFDirDiffUnmark()

" ============================================================
" optional params:
" * path : if empty, use current file
" * option: {
"   'needConfirm' : '0/1, default to g:ZFDirDiffMark_needConfirm',
"   'markDir' : '0/1, whether mark parent dir if path is file, default 1',
"   'unmarkIfSame' : '0/1, whether unmark if mark same path, default 1',
" }
function! ZFDirDiffMark(...)
    let path = get(a:, 1, '')
    let option = get(a:, 2, {})
    let needConfirm = get(option, 'needConfirm', get(g:, 'ZFDirDiffMark_needConfirm', 0))
    let markDir = get(option, 'markDir', 1)

    if empty(path)
        let path = expand('%')
    endif
    if empty(path)
        echo '[ZFDirDiff] no file to mark'
        return
    endif
    if markDir && !isdirectory(path)
        let path = fnamemodify(path, ':h')
    endif
    let path = ZFDirDiffAPI_pathFormat(path, ':p')

    if exists('s:markedPath') && s:markedPath != path
        if !needConfirm || s:confirmDiff(s:markedPath, path) == 'y'
            call ZFDirDiff(s:markedPath, path)
            if get(g:, 'ZFDirDiffMark_addHistory', 1)
                call histadd(':', "call ZFDirDiff('" . s:markedPath . "', '" . path . "')")
            endif
            unlet s:markedPath
        else
            call ZFDirDiffUnmark()
        endif
    elseif get(option, 'unmarkIfSame', 1) && exists('s:markedPath') && s:markedPath == path
        call ZFDirDiffUnmark()
    else
        let s:markedPath = path
        echo '[ZFDirDiff] mark again to diff with: ' . ZFDirDiffAPI_pathHint(path, ':t')
    endif
endfunction

function! ZFDirDiffUnmark()
    if exists('s:markedPath')
        echo '[ZFDirDiff] diff unmarked: ' . ZFDirDiffAPI_pathHint(s:markedPath, ':t')
        unlet s:markedPath
    endif
endfunction

function! ZFDirDiffMarkedPath()
    return get(s:, 'markedPath', '')
endfunction

function! s:confirmDiff(pathL, pathR)
    let hint = []
    call extend(hint, ZFDirDiffUI_confirmHeader(a:pathL, a:pathR))
    call extend(hint, [
                \   '[ZFDirDiff] diff these dirs?',
                \   '  (y)es',
                \   '  (n)o',
                \   '',
                \   'choose: ',
                \ ])

    redraw!
    echo join(hint, "\n")
    try
        let g:ZFDirDiffUI_inputFlag = 1
        let choice = getchar()
    catch
    finally
        let g:ZFDirDiffUI_inputFlag = 0
    endtry
    redraw!

    if 0
    elseif choice == char2nr('y') || choice == char2nr('Y')
        return 'y'
    elseif choice == char2nr('n') || choice == char2nr('N')
        return 'n'
    else
        return 'n'
    endif
endfunction

