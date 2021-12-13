
" ============================================================
" optional params:
" * path : if empty, use current file
" * option: {
"   'needConfirm' : '0/1, default to g:ZFDirDiffMark_needConfirm',
"   'markDir' : '0/1, whether mark parent dir if path is file, default 1',
" }
function! ZF_DirDiffMark(...) abort
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
    let path = ZF_DirDiffPathFormat(path, ':p')

    if exists('s:dir_marked_for_diff') && s:dir_marked_for_diff != path
        if !needConfirm || s:PromptForDiff(s:dir_marked_for_diff, path) == 'y'
            call ZF_DirDiff(s:dir_marked_for_diff, path)
            if get(g:, 'ZFDirDiffMark_addHistory', 1)
                call histadd(':', "call ZF_DirDiff('" . s:dir_marked_for_diff . "', '" . path . "')")
            endif
            " Launched diff, so forget about mark.
            unlet s:dir_marked_for_diff
        else
            let s:dir_marked_for_diff = path
            call s:Print(path, '[ZFDirDiff] mark changed to: %s')
        endif
    else
        let s:dir_marked_for_diff = path
        call s:Print(path, '[ZFDirDiff] mark again to diff with: %s')
    endif
endfunction

function! ZF_DirDiffUnmark()
    if exists('s:dir_marked_for_diff')
        call s:Print(s:dir_marked_for_diff, '[ZFDirDiff] diff unmarked: %s')
        unlet s:dir_marked_for_diff
    endif
endfunction

function! ZF_DirDiffMarked()
    return get(s:, 'dir_marked_for_diff', '')
endfunction

function! s:PromptForDiff(fileLeft, fileRight) abort
    redraw!

    let Fn_headerText = function(g:ZFDirDiffUI_confirmHintHeaderFunc)
    let headerText = Fn_headerText(a:fileLeft, a:fileRight, 'diff')
    let hint = []
    call extend(hint, headerText)
    call extend(hint, [
                \   '[ZFDirDiff] diff these dirs?',
                \   '  (y)es',
                \   '  (n)o',
                \   '',
                \   'choose: ',
                \ ])
    echo join(hint, "\n")

    let choice = getchar()
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

function! s:Print(path, msg)
    let shortname = ZF_DirDiffPathHint(s:dir_marked_for_diff)
    if len(a:msg) + len(shortname) > &columns
        " Try to avoid "Press ENTER to continue"
        let shortname = pathshorten(shortname)
    endif
    echo printf(a:msg, shortname)
endfunction

command! -nargs=* -complete=file ZFDirDiffMark :call ZF_DirDiffMark(<q-args>)
command! -nargs=0 ZFDirDiffUnmark :call ZF_DirDiffUnmark()

