
" op:
"     * dl : delete left
"     * dr : delete right
"     * l2r : copy left to right
"     * r2l : copy right to left
" option: {
"   'deleteAll' : 0/1, // valid for `dl/dr`, whether to also delete no diff files, 0 by default
"   'confirm' : 'a/y/n/q', // previous user confirm, 'y' by default, would be changed during user confirm
"   'autoBackup' : -1/0/1, // whether auto backup, -1 by default, use globalc g:ZFDirDiff_autoBackup
" }
"
" return: a/y/n/q of user confirm
function! ZFDirDiffOp(taskData, diffNode, op, ...)
    let ret = s:ZFDirDiffOp(a:taskData, ZFDirDiffAPI_parentPath(a:diffNode), a:diffNode, a:op, get(a:, 1, {}))
    call ZFDirDiffAPI_update(a:taskData, a:diffNode['parent'])
    return ret
endfunction

function! s:ZFDirDiffOp(taskData, parentPath, diffNode, op, option)
    if !empty(get(a:option, 'confirm', ''))
        if a:option['confirm'] == 'q'
            return a:option['confirm']
        elseif a:option['confirm'] != 'a'
            let a:option['confirm'] = 'y'
        endif
    else
        let a:option['confirm'] = 'y'
    endif

    if 0
    elseif a:op == 'dl' || a:op == 'dr' | return s:opDelete(a:taskData, a:parentPath, a:diffNode, a:op, a:option)
    elseif a:diffNode['type'] == g:ZFDirDiff_T_DIR | return s:op_T_DIR(a:taskData, a:parentPath, a:diffNode, a:op, a:option)
    elseif a:diffNode['type'] == g:ZFDirDiff_T_FILE | return s:op_T_FILE(a:taskData, a:parentPath, a:diffNode, a:op, a:option)
    elseif a:diffNode['type'] == g:ZFDirDiff_T_DIR_LEFT | return s:op_T_DIR_LEFT(a:taskData, a:parentPath, a:diffNode, a:op, a:option)
    elseif a:diffNode['type'] == g:ZFDirDiff_T_DIR_RIGHT | return s:op_T_DIR_RIGHT(a:taskData, a:parentPath, a:diffNode, a:op, a:option)
    elseif a:diffNode['type'] == g:ZFDirDiff_T_FILE_LEFT | return s:op_T_FILE_LEFT(a:taskData, a:parentPath, a:diffNode, a:op, a:option)
    elseif a:diffNode['type'] == g:ZFDirDiff_T_FILE_RIGHT | return s:op_T_FILE_RIGHT(a:taskData, a:parentPath, a:diffNode, a:op, a:option)
    elseif a:diffNode['type'] == g:ZFDirDiff_T_CONFLICT_DIR_LEFT | return s:op_T_CONFLICT_DIR_LEFT(a:taskData, a:parentPath, a:diffNode, a:op, a:option)
    elseif a:diffNode['type'] == g:ZFDirDiff_T_CONFLICT_DIR_RIGHT | return s:op_T_CONFLICT_DIR_RIGHT(a:taskData, a:parentPath, a:diffNode, a:op, a:option)
    endif
endfunction

" function to get the confirm hint, must return a list of string
if !exists('*ZFDirDiffOp_confirmHeader')
    function! ZFDirDiffOp_confirmHeader(taskData, parentPath, diffNode, op, option)
        let text = []
        call add(text, '----------------------------------------')
        if a:op != 'dr'
            call add(text, ZFDirDiffUI_bufLabel(1) . ': ' . a:diffNode['name'])
            call add(text, '    ' . ZFDirDiffAPI_pathHint(a:taskData['pathL'] . a:parentPath . a:diffNode['name'], ':~'))
        endif
        if a:op != 'dl'
            call add(text, ZFDirDiffUI_bufLabel(0) . ': ' . a:diffNode['name'])
            call add(text, '    ' . ZFDirDiffAPI_pathHint(a:taskData['pathR'] . a:parentPath . a:diffNode['name'], ':~'))
        endif
        call add(text, '----------------------------------------')
        call add(text, "\n")
        return text
    endfunction
endif

" ============================================================
function! s:opChoice()
    echo join([
                \   '',
                \   '  (a)ll',
                \   '  (y)es',
                \   '  (n)o',
                \   '  (q)uit',
                \   '',
                \   'choose: ',
                \ ], "\n")

    try
        let g:ZFDirDiffUI_inputFlag = 1
        let choice = getchar()
    catch
    finally
        let g:ZFDirDiffUI_inputFlag = 0
    endtry
    if 0
    elseif choice == char2nr('a') || choice == char2nr('A')
        return 'a'
    elseif choice == char2nr('y') || choice == char2nr('Y')
        return 'y'
    elseif choice == char2nr('n') || choice == char2nr('N')
        return 'n'
    elseif choice == char2nr('q') || choice == char2nr('Q')
        return 'q'
    else
        return 'n'
    endif
endfunction
function! s:opConfirm(hint, taskData, parentPath, diffNode, op, option)
    redraw!
    let headerText = ZFDirDiffOp_confirmHeader(a:taskData, a:parentPath, a:diffNode, a:op, a:option)
    echo join(headerText, "\n")
    echo '[ZFDirDiff] ' . a:hint
    let a:option['confirm'] = s:opChoice()
    redraw!
    return a:option['confirm']
endfunction

function! s:backupAvailable(option)
    return !(!exists('*ZFBackupSave')
                \ || !get(a:option, 'autoBackup', 0)
                \ || (get(a:option, 'autoBackup', 0) == -1 && !get(g:, 'ZFDirDiff_autoBackup', 1))
                \ )
endfunction
function! s:backupFile(option, file)
    if s:backupAvailable(a:option)
        call ZFBackupSave(a:file)
    endif
endfunction
function! s:backupDir(option, dir)
    if s:backupAvailable(a:option)
        call ZFBackupSaveDir(a:dir)
    endif
endfunction

" ============================================================
function! s:opDelete(taskData, parentPath, diffNode, op, option)
    if a:op == 'dl'
        if a:diffNode['type'] == g:ZFDirDiff_T_DIR_RIGHT || a:diffNode['type'] == g:ZFDirDiff_T_FILE_RIGHT
            return a:option['confirm']
        endif
        let path = a:taskData['pathL'] . a:parentPath . a:diffNode['name']
        let isLeft = 1
    else
        if a:diffNode['type'] == g:ZFDirDiff_T_DIR_LEFT || a:diffNode['type'] == g:ZFDirDiff_T_FILE_LEFT
            return a:option['confirm']
        endif
        let path = a:taskData['pathR'] . a:parentPath . a:diffNode['name']
        let isLeft = 0
    endif

    if filereadable(path)
        let isDir = 0
        let needConfirm = get(g:, 'ZFDirDiffUI_confirmDeleteFile', 1)
    else
        let isDir = 1
        let needConfirm = get(g:, 'ZFDirDiffUI_confirmDeleteDir', 1)
    endif

    if a:option['confirm'] != 'a' && needConfirm
        if isLeft
            if isDir
                let hint = 'confirm DELETE?  ' . ZFDirDiffUI_bufLabel(1) . '(dir) <= ' . ZFDirDiffUI_bufLabel(0) . '(___)'
            else
                let hint = 'confirm DELETE?  ' . ZFDirDiffUI_bufLabel(1) . '(file) <= ' . ZFDirDiffUI_bufLabel(0) . '(___)'
            endif
            let choice = s:opConfirm(hint, a:taskData, a:parentPath, a:diffNode, a:op, a:option)
        else
            if isDir
                let hint = 'confirm DELETE?  ' . ZFDirDiffUI_bufLabel(1) . '(___) => ' . ZFDirDiffUI_bufLabel(0) . '(dir)'
            else
                let hint = 'confirm DELETE?  ' . ZFDirDiffUI_bufLabel(1) . '(___) => ' . ZFDirDiffUI_bufLabel(0) . '(file)'
            endif
            let choice = s:opConfirm(hint, a:taskData, a:parentPath, a:diffNode, a:op, a:option)
        endif
        if choice == 'n' || choice == 'q' | return choice | endif
    endif

    if isDir
        call s:backupDir(a:option, path)
        call ZFDirDiffAPI_rmdir(path)
    else
        call s:backupFile(a:option, path)
        call ZFDirDiffAPI_rmfile(path)
    endif
    return a:option['confirm']
endfunction

function! s:opDeleteFile(taskData, parentPath, diffNode, op, option)
    if a:op == 'dl'
        let path = a:taskData['pathL'] . a:parentPath . a:diffNode['name']
    elseif a:op == 'dr'
        let path = a:taskData['pathR'] . a:parentPath . a:diffNode['name']
    else
        let a:option['confirm'] = 'q'
        return a:option['confirm']
    endif
    call s:backupFile(a:option, path)
    call ZFDirDiffAPI_rmfile(path)
    return a:option['confirm']
endfunction

function! s:opDeleteDir(taskData, parentPath, diffNode, op, option)
    if a:op == 'dl'
        let path = a:taskData['pathL'] . a:parentPath . a:diffNode['name']
    elseif a:op == 'dr'
        let path = a:taskData['pathR'] . a:parentPath . a:diffNode['name']
    else
        let a:option['confirm'] = 'q'
        return a:option['confirm']
    endif
    call s:backupDir(a:option, path)
    call ZFDirDiffAPI_rmdir(path)
    return a:option['confirm']
endfunction

function! s:opCopyFile(taskData, parentPath, diffNode, op, option)
    if a:op == 'l2r'
        let from = a:taskData['pathL'] . a:parentPath . a:diffNode['name']
        let to = a:taskData['pathR'] . a:parentPath . a:diffNode['name']
    else
        let from = a:taskData['pathR'] . a:parentPath . a:diffNode['name']
        let to = a:taskData['pathL'] . a:parentPath . a:diffNode['name']
    endif
    call s:backupFile(a:option, to)
    call ZFDirDiffAPI_cpfile(from, to)
    return a:option['confirm']
endfunction

function! s:opCopyDir(taskData, parentPath, diffNode, op, option)
    if a:op == 'l2r'
        call ZFDirDiffAPI_mkdir(a:taskData['pathR'] . a:parentPath . a:diffNode['name'])
    else
        call ZFDirDiffAPI_mkdir(a:taskData['pathL'] . a:parentPath . a:diffNode['name'])
    endif

    let parentPath = a:parentPath . a:diffNode['name'] . '/'
    for child in a:diffNode['child']
        if 0
        elseif a:op == 'l2r'
                    \ && (child['type'] == g:ZFDirDiff_T_DIR_RIGHT || child['type'] == g:ZFDirDiff_T_FILE_RIGHT)
            continue
        elseif a:op == 'r2l'
                    \ && (child['type'] == g:ZFDirDiff_T_DIR_LEFT || child['type'] == g:ZFDirDiff_T_FILE_LEFT)
            continue
        endif
        let choice = s:ZFDirDiffOp(a:taskData, parentPath, child, a:op, a:option)
        if choice == 'q' | return 'q' | endif
    endfor
    return a:option['confirm']
endfunction

" ============================================================
function! s:op_T_DIR(taskData, parentPath, diffNode, op, option)
    if a:option['confirm'] != 'a' && get(g:, 'ZFDirDiffUI_confirmSyncDir', 1)
        let hint = 'confirm sync?  ' . (a:op == 'l2r' ? ZFDirDiffUI_bufLabel(1) . '(dir) => ' . ZFDirDiffUI_bufLabel(0) . '(dir)' : ZFDirDiffUI_bufLabel(1) . '(dir) <= [RIGHT(dir)]')
        let choice = s:opConfirm(hint, a:taskData, a:parentPath, a:diffNode, a:op, a:option)
        if choice == 'n' || choice == 'q' | return choice | endif
    endif
    return s:opCopyDir(a:taskData, a:parentPath, a:diffNode, a:op, a:option)
endfunction

function! s:op_T_FILE(taskData, parentPath, diffNode, op, option)
    if a:diffNode['diff'] == 0
        if !get(g:, 'ZFDirDiffUI_syncSameFile', 0)
            return a:option['confirm']
        endif
        if a:option['confirm'] != 'a' && get(g:, 'ZFDirDiffUI_confirmSyncFile', 1)
            let hint = 'confirm sync?  ' . (a:op == 'l2r' ? ZFDirDiffUI_bufLabel(1) . '(file) => '. ZFDirDiffUI_bufLabel(0) . '(file)' : ZFDirDiffUI_bufLabel(1) . '(file) <= [RIGHT(file)]')
            let choice = s:opConfirm(hint, a:taskData, a:parentPath, a:diffNode, a:op, a:option)
            if choice == 'n' || choice == 'q' | return choice | endif
        endif
        return s:opCopyFile(a:taskData, a:parentPath, a:diffNode, a:op, a:option)
    else
        if a:option['confirm'] != 'a' && get(g:, 'ZFDirDiffUI_confirmSyncFile', 1)
            let hint = 'confirm sync?  ' . (a:op == 'l2r' ? ZFDirDiffUI_bufLabel(1) . '(file) => ' . ZFDirDiffUI_bufLabel(0) . '(file)' : ZFDirDiffUI_bufLabel(1) . '(file) <= ' . ZFDirDiffUI_bufLabel(0) . '(file)')
            let choice = s:opConfirm(hint, a:taskData, a:parentPath, a:diffNode, a:op, a:option)
            if choice == 'n' || choice == 'q' | return choice | endif
        endif
        return s:opCopyFile(a:taskData, a:parentPath, a:diffNode, a:op, a:option)
    endif
endfunction

function! s:op_T_DIR_LEFT(taskData, parentPath, diffNode, op, option)
    if a:op == 'l2r'
        if a:option['confirm'] != 'a' && get(g:, 'ZFDirDiffUI_confirmCopyDir', 1)
            let hint = 'confirm copy?  ' . ZFDirDiffUI_bufLabel(1) . '(dir) => ' . ZFDirDiffUI_bufLabel(0) . '(___)'
            let choice = s:opConfirm(hint, a:taskData, a:parentPath, a:diffNode, a:op, a:option)
            if choice == 'n' || choice == 'q' | return choice | endif
        endif
        return s:opCopyDir(a:taskData, a:parentPath, a:diffNode, a:op, a:option)
    else
        if a:option['confirm'] != 'a' && get(g:, 'ZFDirDiffUI_confirmDeleteDir', 1)
            let hint = 'confirm DELETE?  ' . ZFDirDiffUI_bufLabel(1) . '(dir) <= ' . ZFDirDiffUI_bufLabel(0) . '(___)'
            let choice = s:opConfirm(hint, a:taskData, a:parentPath, a:diffNode, a:op, a:option)
            if choice == 'n' || choice == 'q' | return choice | endif
        endif
        return s:opDeleteDir(a:taskData, a:parentPath, a:diffNode, 'dl', a:option)
    endif
endfunction

function! s:op_T_DIR_RIGHT(taskData, parentPath, diffNode, op, option)
    if !(a:op == 'l2r')
        if a:option['confirm'] != 'a' && get(g:, 'ZFDirDiffUI_confirmCopyDir', 1)
            let hint = 'confirm copy?  ' . ZFDirDiffUI_bufLabel(1) . '(___) <= ' . ZFDirDiffUI_bufLabel(0) . '(dir)'
            let choice = s:opConfirm(hint, a:taskData, a:parentPath, a:diffNode, a:op, a:option)
            if choice == 'n' || choice == 'q' | return choice | endif
        endif
        return s:opCopyDir(a:taskData, a:parentPath, a:diffNode, a:op, a:option)
    else
        if a:option['confirm'] != 'a' && get(g:, 'ZFDirDiffUI_confirmDeleteDir', 1)
            let hint = 'confirm DELETE?  ' . ZFDirDiffUI_bufLabel(1) . '(___) => ' . ZFDirDiffUI_bufLabel(0) . '(dir)'
            let choice = s:opConfirm(hint, a:taskData, a:parentPath, a:diffNode, a:op, a:option)
            if choice == 'n' || choice == 'q' | return choice | endif
        endif
        return s:opDeleteDir(a:taskData, a:parentPath, a:diffNode, 'dr', a:option)
    endif
endfunction

function! s:op_T_FILE_LEFT(taskData, parentPath, diffNode, op, option)
    if a:op == 'l2r'
        if a:option['confirm'] != 'a' && get(g:, 'ZFDirDiffUI_confirmCopyFile', 0)
            let hint = 'confirm copy?  ' . ZFDirDiffUI_bufLabel(1) . '(file) => ' . ZFDirDiffUI_bufLabel(0) . '(___)'
            let choice = s:opConfirm(hint, a:taskData, a:parentPath, a:diffNode, a:op, a:option)
            if choice == 'n' || choice == 'q' | return choice | endif
        endif
        return s:opCopyFile(a:taskData, a:parentPath, a:diffNode, a:op, a:option)
    else
        if a:option['confirm'] != 'a' && get(g:, 'ZFDirDiffUI_confirmDeleteFile', 1)
            let hint = 'confirm DELETE?  ' . ZFDirDiffUI_bufLabel(1) . '(file) <= ' . ZFDirDiffUI_bufLabel(0) . '(___)'
            let choice = s:opConfirm(hint, a:taskData, a:parentPath, a:diffNode, a:op, a:option)
            if choice == 'n' || choice == 'q' | return choice | endif
        endif
        return s:opDeleteFile(a:taskData, a:parentPath, a:diffNode, 'dl', a:option)
    endif
endfunction

function! s:op_T_FILE_RIGHT(taskData, parentPath, diffNode, op, option)
    if !(a:op == 'l2r')
        if a:option['confirm'] != 'a' && get(g:, 'ZFDirDiffUI_confirmCopyFile', 0)
            let hint = 'confirm copy?  ' . ZFDirDiffUI_bufLabel(1) . '(___) <= ' . ZFDirDiffUI_bufLabel(0) . '(file)'
            let choice = s:opConfirm(hint, a:taskData, a:parentPath, a:diffNode, a:op, a:option)
            if choice == 'n' || choice == 'q' | return choice | endif
        endif
        return s:opCopyFile(a:taskData, a:parentPath, a:diffNode, a:op, a:option)
    else
        if a:option['confirm'] != 'a' && get(g:, 'ZFDirDiffUI_confirmDeleteFile', 1)
            let hint = 'confirm DELETE?  ' . ZFDirDiffUI_bufLabel(1) . '(___) => ' . ZFDirDiffUI_bufLabel(0) . '(file)'
            let choice = s:opConfirm(hint, a:taskData, a:parentPath, a:diffNode, a:op, a:option)
            if choice == 'n' || choice == 'q' | return choice | endif
        endif
        return s:opDeleteFile(a:taskData, a:parentPath, a:diffNode, 'dr', a:option)
    endif
endfunction

function! s:op_T_CONFLICT_DIR_LEFT(taskData, parentPath, diffNode, op, option)
    if a:op == 'l2r'
        if a:option['confirm'] != 'a' && get(g:, 'ZFDirDiffUI_confirmDeleteFile', 1)
            let hint = 'confirm sync CONFLICT?  ' . ZFDirDiffUI_bufLabel(1) . '(dir) => ' . ZFDirDiffUI_bufLabel(0) . '(file)'
            let choice = s:opConfirm(hint, a:taskData, a:parentPath, a:diffNode, a:op, a:option)
            if choice == 'n' || choice == 'q' | return choice | endif
        endif
        call s:opDeleteFile(a:taskData, a:parentPath, a:diffNode, 'dr', a:option)
        return s:opCopyDir(a:taskData, a:parentPath, a:diffNode, a:op, a:option)
    else
        if a:option['confirm'] != 'a' && get(g:, 'ZFDirDiffUI_confirmDeleteDir', 1)
            let hint = 'confirm sync CONFLICT?  ' . ZFDirDiffUI_bufLabel(1) . '(dir) <= ' . ZFDirDiffUI_bufLabel(0) . '(file)'
            let choice = s:opConfirm(hint, a:taskData, a:parentPath, a:diffNode, a:op, a:option)
            if choice == 'n' || choice == 'q' | return choice | endif
        endif
        call s:opDeleteDir(a:taskData, a:parentPath, a:diffNode, 'dl', a:option)
        return s:opCopyFile(a:taskData, a:parentPath, a:diffNode, a:op, a:option)
    endif
endfunction

function! s:op_T_CONFLICT_DIR_RIGHT(taskData, parentPath, diffNode, op, option)
    if !(a:op == 'l2r')
        if a:option['confirm'] != 'a' && get(g:, 'ZFDirDiffUI_confirmDeleteFile', 1)
            let hint = 'confirm sync CONFLICT?  ' . ZFDirDiffUI_bufLabel(1) . '(file) <= ' . ZFDirDiffUI_bufLabel(0) . '(dir)'
            let choice = s:opConfirm(hint, a:taskData, a:parentPath, a:diffNode, a:op, a:option)
            if choice == 'n' || choice == 'q' | return choice | endif
        endif
        call s:opDeleteFile(a:taskData, a:parentPath, a:diffNode, 'dl', a:option)
        return s:opCopyDir(a:taskData, a:parentPath, a:diffNode, a:op, a:option)
    else
        if a:option['confirm'] != 'a' && get(g:, 'ZFDirDiffUI_confirmDeleteDir', 1)
            let hint = 'confirm sync CONFLICT?  ' . ZFDirDiffUI_bufLabel(1) . '(file) => ' . ZFDirDiffUI_bufLabel(0) . '(dir)'
            let choice = s:opConfirm(hint, a:taskData, a:parentPath, a:diffNode, a:op, a:option)
            if choice == 'n' || choice == 'q' | return choice | endif
        endif
        call s:opDeleteDir(a:taskData, a:parentPath, a:diffNode, 'dr', a:option)
        return s:opCopyFile(a:taskData, a:parentPath, a:diffNode, a:op, a:option)
    endif
endfunction

