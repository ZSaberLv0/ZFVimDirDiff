
" ============================================================
function! s:Mark(...) abort
    if len(a:000) > 0
        " Accept input path
        let path = a:1
    else
        " Or current file's path
        let path = expand('%')
    endif
    if !isdirectory(path)
        let path = fnamemodify(path, ':h')
    endif
    let path = ZF_DirDiffPathFormat(path, ':~')
    
    if exists("s:dir_marked_for_diff") && s:dir_marked_for_diff != path
        let choice = s:PromptForDiff(s:dir_marked_for_diff, path)
        if choice == 'y'
            call ZF_DirDiff(s:dir_marked_for_diff, path)
            " Launched diff, so forget about mark.
            unlet s:dir_marked_for_diff
        else
            call s:MarkAndPrint(path, "\n[ZFDirDiff] Instead marked %s for diff")
        endif
    else
        call s:MarkAndPrint(path, "[ZFDirDiff] Marked %s for diff")
    endif
endfunction

function! s:PromptForDiff(left, right) abort
    echo "Diff directories:\n  ".. a:left .."\n  ".. a:right .."\n\n"
    echo "\n"
    echo '  (y)es'
    echo '  (n)o'
    echo "\n"
    echo 'choose: '

    let choice = getchar()
    if 0
    elseif choice == char2nr('y') || choice == char2nr('Y')
        return 'y'
    elseif choice == char2nr('n') || choice == char2nr('N')
        return 'n'
    else
        return 'n'
    endif
endfunction

function! s:MarkAndPrint(path, msg)
    let s:dir_marked_for_diff = a:path
    let shortname = s:dir_marked_for_diff
    if len(a:msg) + len(shortname) > &columns
        " Try to avoid "Press ENTER to continue"
        let shortname = pathshorten(shortname)
    endif
    echo printf(a:msg, shortname)
endfunction

command! -nargs=? -complete=file ZFDirMark :call s:Mark(<f-args>)
