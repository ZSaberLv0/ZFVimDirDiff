
command! -nargs=+ -complete=file ZFDirDiff :call ZFDirDiff(<f-args>)

" tab local var:
" * t:ZFDirDiff_taskData
" * t:ZFDirDiff_ownerTab : start from which tab
" * t:ZFDirDiff_bufnrL : bufnr of left buffer
" * t:ZFDirDiff_bufnrR : bufnr of right buffer
" * t:ZFDirDiff_markToDiff : { // exist only when mark exist
"     'bufnr' : bufnr, // which buf marked
"     'diffNode' : {...}, // marked diffNode
"   }
" * t:ZFDirDiff_markToSync : [ // exist only when mark exist
"     {
"       'bufnr' : bufnr, // which buf marked
"       'diffNode' : {...}, // marked diffNode
"     },
"     ...
"   ]
"
" option: { // all option is optional
"   'reuseTab' : 0/1, // whether to reuse current tab, g:ZFDirDiff_reuseTab by default
" }
function! ZFDirDiff(fileL, fileR, ...)
    let pathL = ZFDirDiffAPI_pathFormat(a:fileL)
    let pathR = ZFDirDiffAPI_pathFormat(a:fileR)
    if !isdirectory(pathL) || !isdirectory(pathR)
        call s:fileDiffUI_start(-1, {}, pathL, pathR)
        return
    endif

    let option = get(a:, 1, {})
    call s:diffUI_create(get(option, 'reuseTab', get(g:, 'ZFDirDiff_reuseTab', 0)))
    call s:diffUI_start(a:fileL, a:fileR)
    call s:diffUI_cursorReset(option)
endfunction

if !exists('*ZFDirDiffUI_cbHeader')
    function! ZFDirDiffUI_cbHeader(taskData)
        let headerL = [
                    \   ZFDirDiffUI_bufLabel(1) . ': ' . ZFDirDiffAPI_pathHint(a:taskData['pathL'], ':~'),
                    \   ZFDirDiffUI_bufLabel(1) . ': ' . ZFDirDiffAPI_pathHint(a:taskData['pathL'], ':.'),
                    \   '------------------------------------------------------------',
                    \ ]
        let headerR = [
                    \   ZFDirDiffUI_bufLabel(0) . ': ' . ZFDirDiffAPI_pathHint(a:taskData['pathR'], ':~'),
                    \   ZFDirDiffUI_bufLabel(0) . ': ' . ZFDirDiffAPI_pathHint(a:taskData['pathR'], ':.'),
                    \   '------------------------------------------------------------',
                    \ ]
        return {
                    \   'headerL' : headerL,
                    \   'headerR' : headerR,
                    \ }
    endfunction
endif

" isDir:
" * 0 : file
" * 1 : dir
" * -1 : not exist
function! ZFDirDiffUI_cbDiffLineDefault(taskData, diffNode, depth, isLeft, isDir)
    if a:isDir == -1
        return ''
    else
        return printf('%s%s%s%s'
                    \ , repeat(' ', a:depth * get(g:, 'ZFDirDiffUI_tabstop', 2))
                    \ , a:isDir
                    \     ? a:diffNode['open']
                    \         ? get(g:, 'ZFDirDiffUIChar_dir_prefix_opened', '~ ')
                    \         : get(g:, 'ZFDirDiffUIChar_dir_prefix_closed', '+ ')
                    \     : get(g:, 'ZFDirDiffUIChar_file_prefix', '  ')
                    \ , a:diffNode['name']
                    \ , a:isDir
                    \     ? get(g:, 'ZFDirDiffUIChar_dir_postfix', '/')
                    \     : get(g:, 'ZFDirDiffUIChar_file_postfix', '')
                    \ )
    endif
endfunction

if !exists('*ZFDirDiffUI_statusline')
    function! ZFDirDiffUI_statusline(isLeft)
        if !exists('t:ZFDirDiff_taskData')
            return ''
        endif
        return ZFDirDiffUI_bufLabel(a:isLeft) . ': '
                    \ . substitute(t:ZFDirDiff_taskData[a:isLeft ? 'fileL' : 'fileR'], '%', '%%', 'g')
                    \ . '%=%k %3p%%'
    endfunction
endif

if !exists('*ZFDirDiffUI_confirmHeader')
    function! ZFDirDiffUI_confirmHeader(pathL, pathR)
        let text = []
        call add(text, '------------------------------------------------------------')
        if !empty(a:pathL)
            let path = ZFDirDiffAPI_pathHint(a:pathL, ':t')
            let relpath = ZFDirDiffAPI_pathHint(a:pathL, ':~')
            call add(text, ZFDirDiffUI_bufLabel(1) . ': ' . path)
            if path != relpath
                call add(text, '    ' . relpath)
            endif
        endif
        if !empty(a:pathR)
            let path = ZFDirDiffAPI_pathHint(a:pathR, ':t')
            let relpath = ZFDirDiffAPI_pathHint(a:pathR, ':~')
            call add(text, ZFDirDiffUI_bufLabel(0) . ': ' . path)
            if path != relpath
                call add(text, '    ' . relpath)
            endif
        endif
        call add(text, '------------------------------------------------------------')
        call add(text, "\n")
        return text
    endfunction
endif

function! ZFDirDiffUI_jumpWin(bufnr, ...)
    let isLeft = get(a:, 1, -1)
    if a:bufnr < 0
        return 0
    endif
    let winnr = bufwinnr(a:bufnr)
    if winnr < 0
        if isLeft >= 0
            " fallback, just try to use proper side window
            if isLeft
                wincmd h
            else
                wincmd l
            endif
            return 1
        else
            return 0
        endif
    else
        try
            execute winnr . 'wincmd w'
        catch
            return 0
        finally
            return 1
        endtry
    endif
endfunction

function! ZFDirDiffUI_diffNodeAtLine(taskData, iLine)
    let index = a:iLine - 1
    if index < len(get(a:taskData, 'childVisible', []))
        return a:taskData['childVisible'][index]
    else
        return {}
    endif
endfunction
function! ZFDirDiffUI_diffNodeUnderCursor()
    if !exists('t:ZFDirDiff_taskData')
        echomsg '[ZFDirDiff] no previous diff task'
        return {}
    endif
    return ZFDirDiffUI_diffNodeAtLine(t:ZFDirDiff_taskData, line('.'))
endfunction

" bufnr: -1/t:ZFDirDiff_bufnrL/t:ZFDirDiff_bufnrR
function! ZFDirDiffUI_diffNodesForRange(first, last, ...)
    let bufnr = get(a:, 1, -1)
    if !exists('t:ZFDirDiff_taskData')
        echomsg '[ZFDirDiff] no previous diff task'
        return []
    endif
    let iFirst = a:first - 1
    if iFirst >= len(t:ZFDirDiff_taskData['childVisible'])
        return []
    endif
    let iLast = a:last - 1
    if iLast >= len(t:ZFDirDiff_taskData['childVisible'])
        let iLast = len(t:ZFDirDiff_taskData['childVisible']) - 1
    endif
    execute printf("let diffNodes=t:ZFDirDiff_taskData['childVisible'][%d:%d]", iFirst, iLast)

    if bufnr == t:ZFDirDiff_bufnrL || bufnr == t:ZFDirDiff_bufnrR
        if bufnr == t:ZFDirDiff_bufnrL
            let pattern = [
                        \   g:ZFDirDiff_T_DIR_RIGHT,
                        \   g:ZFDirDiff_T_FILE_RIGHT,
                        \ ]
        else
            let pattern = [
                        \   g:ZFDirDiff_T_DIR_LEFT,
                        \   g:ZFDirDiff_T_FILE_LEFT,
                        \ ]
        endif
        let i = len(diffNodes) - 1
        while i >= 0
            if empty(diffNodes[i])
                        \ || index(pattern, diffNodes[i]['type']) >= 0
                call remove(diffNodes, i)
            endif
            let i -= 1
        endwhile
    else
        let i = len(diffNodes) - 1
        while i >= 0
            if empty(diffNodes[i])
                call remove(diffNodes, i)
            endif
            let i -= 1
        endwhile
    endif

    return diffNodes
endfunction

" bufnrSrc: t:ZFDirDiff_bufnrL / t:ZFDirDiff_bufnrR
" bufnrSrc should be the source side you need to obtain diffNodes
"
" for example:
" * you are inside left and want to sync from right to left,
"   bufnrSrc should be t:ZFDirDiff_bufnrR
" * you are inside left and want to sync from left to right,
"   bufnrSrc should be t:ZFDirDiff_bufnrL
"
" if includeThereOnly==1, nodes that does not exist in bufnrSrc would also appended
function! ZFDirDiffUI_diffNodesForSync(first, last, bufnrSrc, ...)
    let includeThereOnly = get(a:, 1, 0)

    if !exists('t:ZFDirDiff_taskData')
        echomsg '[ZFDirDiff] no previous diff task'
        return []
    endif
    if a:bufnrSrc != t:ZFDirDiff_bufnrL && a:bufnrSrc != t:ZFDirDiff_bufnrR
        echomsg '[ZFDirDiff] invalid bufnr: ' . a:bufnrSrc
                    \ . ', should be one of: '
                    \ . t:ZFDirDiff_bufnrL
                    \ . ' ' . t:ZFDirDiff_bufnrR
        return []
    endif
    if empty(get(t:, 'ZFDirDiff_markToSync', []))
        silent call ZFDirDiffUIAction_markToSyncForRange(a:first, a:last, 'add', a:bufnrSrc, includeThereOnly)
    endif
    if empty(get(t:, 'ZFDirDiff_markToSync', []))
        return []
    endif

    let diffNodes = []
    let allParentPath = {}
    for markToSync in t:ZFDirDiff_markToSync
        if markToSync['bufnr'] == a:bufnrSrc
            call add(diffNodes, markToSync['diffNode'])
            let allParentPath[ZFDirDiffAPI_parentPath(markToSync['diffNode'])] = 1
        endif
    endfor

    " filter out parent if children marked
    "
    " typical case:
    "   fileA     <= range start
    "   dirA/
    "       fileB <= range end
    "       fileC
    " dirA should be filtered to prevent fileC to be processed
    let i = len(diffNodes) - 1
    while i >= 0
        let diffNode = diffNodes[i]
        let path = ZFDirDiffAPI_parentPath(diffNode) . diffNode['name']
        if get(allParentPath, path, 0)
            call remove(diffNodes, i)
        endif
        let i -= 1
    endwhile

    return diffNodes
endfunction

" ============================================================
if !exists('s:defKeymap')
    let s:defKeymap = {}
endif
function! s:makeKeymap(action, option, def, ...)
    let supportRange = get(a:, 1, 0)
    let s:defKeymap[a:option] = a:def
    for k in get(g:, a:option, a:def)
        if !empty(k)
            execute 'nnoremap <buffer><silent> ' . k . ' :call ' . a:action . '()<cr>'
            if supportRange
                execute 'xnoremap <buffer><silent> ' . k . ' :call ' . a:action . '()<cr>'
            endif
        endif
    endfor
endfunction
function! ZFDirDiffUI_getKeymap(option)
    return get(g:, a:option, get(s:defKeymap, a:option, []))
endfunction

" ============================================================
function! s:diffUI_create(reuseTab)
    if a:reuseTab
                \ && exists('t:ZFDirDiff_taskData')
                \ && winnr('$') >= 2
                \ && exists('t:ZFDirDiff_bufnrL')
                \ && exists('t:ZFDirDiff_bufnrR')
                \ && bufloaded(t:ZFDirDiff_bufnrL)
                \ && bufloaded(t:ZFDirDiff_bufnrR)
        let bufnr = bufnr('%')
        wincmd h
        wincmd k
        execute 'b' . t:ZFDirDiff_bufnrL
        call s:diffUI_makeKeymap()
        wincmd l
        wincmd k
        execute 'b' . t:ZFDirDiff_bufnrR
        call s:diffUI_makeKeymap()

        if bufnr == t:ZFDirDiff_bufnrL
            wincmd h
            wincmd k
        elseif bufnr == t:ZFDirDiff_bufnrR
            wincmd l
            wincmd k
        endif
        return
    endif

    let ownerTab = tabpagenr()
    tabnew
    let t:ZFDirDiff_ownerTab = ownerTab

    vsplit
    enew
    wincmd h
    wincmd k
    execute 'let t:ZFDirDiff_bufnrL = ' . bufnr('%')
    call s:diffUI_bufSetup(1)
    wincmd l
    wincmd k
    execute 'let t:ZFDirDiff_bufnrR = ' . bufnr('%')
    call s:diffUI_bufSetup(0)
endfunction

if !exists('*ZFDirDiffUI_bufLabel')
    function! ZFDirDiffUI_bufLabel(isLeft)
        return a:isLeft ? '[LEFT]': '[RIGHT]'
    endfunction
endif

function! s:diffUI_bufSetup(isLeft)
    call s:diffUI_makeKeymap()
    execute 'set filetype=' . get(g:, 'ZFDirDiffUI_filetype', 'ZFDirDiff')
    execute 'setlocal statusline=%!ZFDirDiffUI_statusline(' . (a:isLeft ? '1' : '0') . ')'
    execute 'setlocal tabstop=' . get(g:, 'ZFDirDiffUI_tabstop', 2)
    execute 'setlocal softtabstop=' . get(g:, 'ZFDirDiffUI_tabstop', 2)
    setlocal buftype=nofile
    setlocal bufhidden=delete
    setlocal buflisted
    setlocal nowrap
    setlocal noswapfile
    execute 'silent! file ' . ZFDirDiffUI_bufLabel(a:isLeft) . ' ' . bufnr('%')
    setlocal nomodified
    setlocal nomodifiable
    set scrollbind
    set cursorbind
    execute 'augroup ZFDirDiff_diffUI_bufOnDelete_augroup_' . bufnr('%')
    autocmd!
    autocmd BufDelete <buffer> set noscrollbind | set nocursorbind
                \| call s:diffUI_bufOnDelete()
    autocmd BufHidden <buffer> set noscrollbind | set nocursorbind
    autocmd BufEnter <buffer> set scrollbind | set cursorbind
    execute 'augroup END'
endfunction

function! s:diffUI_bufOnDelete()
    let bufnr = expand('<abuf>')

    execute 'augroup ZFDirDiff_diffUI_bufOnDelete_augroup_' . bufnr
    autocmd!
    execute 'augroup END'

    if exists('t:ZFDirDiff_taskData')
                \ && (!buflisted(t:ZFDirDiff_bufnrL) || bufnr == t:ZFDirDiff_bufnrL)
                \ && (!buflisted(t:ZFDirDiff_bufnrR) || bufnr == t:ZFDirDiff_bufnrR)
        call ZFDirDiffUIAction_quit()
    endif
endfunction

function! s:diffUI_tabAttach(tabpagenr, taskData)
    if !exists('##TabClosed')
        return
    endif

    " <tabpagenr, taskData>
    " used to auto stop diff task when tab accidentally closed by user
    if !exists('s:diffUI_tabAttachMap')
        let s:diffUI_tabAttachMap = {}
    endif

    let s:diffUI_tabAttachMap[a:tabpagenr] = a:taskData

    execute 'augroup ZFDirDiff_diffUI_tabAttach_augroup_' . a:tabpagenr
    autocmd!
    autocmd TabClosed * call s:diffUI_tabDetachUnexpected(expand('<afile>'))
    execute 'augroup END'
endfunction

function! s:diffUI_tabDetach(tabpagenr, taskData)
    if !exists('##TabClosed')
        return
    endif

    execute 'augroup ZFDirDiff_diffUI_tabAttach_augroup_' . a:tabpagenr
    autocmd!
    execute 'augroup END'

    if exists("s:diffUI_tabAttachMap[a:tabpagenr]")
        unlet s:diffUI_tabAttachMap[a:tabpagenr]
    endif
endfunction

function! s:diffUI_tabDetachUnexpected(tabpagenr)
    if !exists("s:diffUI_tabAttachMap[a:tabpagenr]")
        return
    endif
    let taskData = s:diffUI_tabAttachMap[a:tabpagenr]
    call s:diffUI_tabDetach(a:tabpagenr, taskData)
    call ZFDirDiffAPI_cleanup(taskData)
    call ZFDirDiffHLImpl_cleanup(taskData)
endfunction

function! s:diffUI_start(fileL, fileR)
    if exists('t:ZFDirDiff_taskData')
        call s:diffUI_tabDetach(tabpagenr(), t:ZFDirDiff_taskData)
        call ZFDirDiffAPI_cleanup(t:ZFDirDiff_taskData)
        call ZFDirDiffHLImpl_cleanup(t:ZFDirDiff_taskData)
    endif
    call s:diffUI_markClear()
    let t:ZFDirDiff_taskData = ZFDirDiffAPI_init(a:fileL, a:fileR, {
                \   'cbDataChanged' : function('ZFDirDiffUI_cbDataChanged'),
                \   'cbHeader' : function('ZFDirDiffUI_cbHeader'),
                \   'cbTail' : exists('*ZFDirDiffUI_cbTail') ? function('ZFDirDiffUI_cbTail') : {},
                \   'cbDiffLine' : exists('*ZFDirDiffUI_cbDiffLine') ? function('ZFDirDiffUI_cbDiffLine') : {},
                \ })
    if empty(t:ZFDirDiff_taskData)
        unlet t:ZFDirDiff_taskData
        return
    endif
    call s:diffUI_tabAttach(tabpagenr(), t:ZFDirDiff_taskData)
    call ZFDirDiffHLImpl_init(t:ZFDirDiff_taskData)
    call ZFDirDiffAPI_update(t:ZFDirDiff_taskData)

    call ZFDirDiffAPI_dataChangedImmediately(t:ZFDirDiff_taskData)
endfunction

function! ZFDirDiffUI_cbDataChanged()
    if !exists('t:ZFDirDiff_taskData')
        return
    endif
    let bufnrSaved = bufnr('%')
    let cursorSaved = getpos('.')
    if t:ZFDirDiff_taskData['cursorLine'] > 0
        let cursorSaved[1] = t:ZFDirDiff_taskData['cursorLine']
        let t:ZFDirDiff_taskData['cursorLine'] = 0
    endif

    noautocmd call s:diffUI_redraw(bufnrSaved, cursorSaved)
    call ZFDirDiffHLImpl_dataChanged(t:ZFDirDiff_taskData)
endfunction

if exists('*setbufline') && exists('*deletebufline')
    function! s:diffUI_redraw(bufnrSaved, cursorSaved)
        call s:diffUI_bufContentUpdate(t:ZFDirDiff_bufnrL, t:ZFDirDiff_taskData['linesL'])
        call s:diffUI_bufContentUpdate(t:ZFDirDiff_bufnrR, t:ZFDirDiff_taskData['linesR'])

        if a:bufnrSaved == t:ZFDirDiff_bufnrL || a:bufnrSaved == t:ZFDirDiff_bufnrR
            call setpos('.', a:cursorSaved)
        endif
        if a:bufnrSaved == t:ZFDirDiff_bufnrL
            call ZFDirDiffUI_jumpWin(a:bufnrSaved, 1)
        elseif a:bufnrSaved == t:ZFDirDiff_bufnrR
            call ZFDirDiffUI_jumpWin(a:bufnrSaved, 0)
        endif
    endfunction
    function! s:diffUI_bufContentUpdate(bufnr, lines)
        call setbufvar(a:bufnr, '&modifiable', 1)
        if len(getbufline(a:bufnr, 1, '$')) > len(a:lines)
            silent! call deletebufline(a:bufnr, 1, '$')
        endif
        call setbufline(a:bufnr, 1, a:lines)
        call setbufvar(a:bufnr, '&modified', 0)
        call setbufvar(a:bufnr, '&modifiable', 0)
    endfunction
else
    function! s:diffUI_redraw(bufnrSaved, cursorSaved)
        call ZFDirDiffUI_jumpWin(t:ZFDirDiff_bufnrL, 1)
        execute 'b' . t:ZFDirDiff_bufnrL
        call s:diffUI_bufContentUpdate(t:ZFDirDiff_bufnrL, t:ZFDirDiff_taskData['linesL'])
        call setpos('.', a:cursorSaved)

        call ZFDirDiffUI_jumpWin(t:ZFDirDiff_bufnrR, 0)
        execute 'b' . t:ZFDirDiff_bufnrR
        call s:diffUI_bufContentUpdate(t:ZFDirDiff_bufnrR, t:ZFDirDiff_taskData['linesR'])
        call setpos('.', a:cursorSaved)

        if a:bufnrSaved == t:ZFDirDiff_bufnrL
            call ZFDirDiffUI_jumpWin(t:ZFDirDiff_bufnrL, 1)
        endif
    endfunction
    function! s:diffUI_bufContentUpdate(bufnr, lines)
        setlocal modifiable
        if line('$') > len(a:lines)
            silent! normal! ggdG
        endif
        call setline(1, a:lines)
        setlocal nomodified
        setlocal nomodifiable
    endfunction
endif

function! s:diffUI_cursorReset(option)
    if !exists('t:ZFDirDiff_taskData')
        return
    endif
    call ZFDirDiffUI_jumpWin(t:ZFDirDiff_bufnrR, 0)
    call setpos('.', [0, t:ZFDirDiff_taskData['headerLen'] + 1, 1, 1])
endfunction

function! s:diffUI_markClear()
    if exists('t:ZFDirDiff_markToDiff')
        unlet t:ZFDirDiff_markToDiff
    endif
    if exists('t:ZFDirDiff_markToSync')
        unlet t:ZFDirDiff_markToSync
    endif
endfunction

function! s:diffUI_diffJump(isNext)
    if !exists('t:ZFDirDiff_taskData')
        echomsg '[ZFDirDiff] no previous diff task'
        return 0
    endif

    if a:isNext
        let iOffset = 1
        let iEnd = len(t:ZFDirDiff_taskData['childVisible'])
        let i = line('.')
    else
        let iOffset = -1
        let iEnd = t:ZFDirDiff_taskData['headerLen'] - 1
        let i = line('.') - 2
    endif

    while i != iEnd
        let diffNode = t:ZFDirDiff_taskData['childVisible'][i]
        if !empty(diffNode) && diffNode['diff'] == 1
            let curPos = getpos('.')
            let curPos[1] = i + 1
            call setpos('.', curPos)
            normal! zz
            return 1
        endif
        let i += iOffset
    endwhile
    return 0
endfunction

function! s:diffUI_diffJumpFile(isNext)
    if !exists('t:ZFDirDiff_taskData')
        echomsg '[ZFDirDiff] no previous diff task'
        return 0
    endif
    let index = line('.') - 1
    if a:isNext
        if index < t:ZFDirDiff_taskData['headerLen']
            return s:diffUI_diffJumpFileNext({})
        elseif index >= len(t:ZFDirDiff_taskData['childVisible']) - t:ZFDirDiff_taskData['tailLen']
            return 0
        else
            return s:diffUI_diffJumpFileNext(t:ZFDirDiff_taskData['childVisible'][index])
        endif
    else
        if index < t:ZFDirDiff_taskData['headerLen']
            return 0
        elseif index >= len(t:ZFDirDiff_taskData['childVisible']) - t:ZFDirDiff_taskData['tailLen']
            return s:diffUI_diffJumpFilePrev({})
        else
            return s:diffUI_diffJumpFilePrev(t:ZFDirDiff_taskData['childVisible'][index])
        endif
    endif
endfunction

function! s:diffUI_diffJumpFilePrev(cursorNode)
    let skipFlag = 0
    if empty(a:cursorNode)
        let toCheck = copy(t:ZFDirDiff_taskData['child'])
    else
        let toCheck = [a:cursorNode]
        let skipFlag = 1
    endif

    let target = {}
    while !empty(toCheck)
        let check = remove(toCheck, -1)
        if !skipFlag
            if !ZFDirDiffAPI_diffNodeCanOpen(check)
                if check['diff'] == 1
                    let target = check
                    break
                endif
            endif
        endif

        if !skipFlag && ZFDirDiffAPI_diffNodeCanOpen(check) && !empty(check['child'])
            " search children
            call add(toCheck, check['child'][-1])
        else
            " search and add prev sibling
            let sibling = check
            while !empty(sibling['parent'])
                let childList = sibling['parent']['child']
                let index = ZFDirDiffAPI_diffNodeIndexUnsafe(childList, sibling)
                if index > 0
                    call add(toCheck, childList[index - 1])
                    break
                endif
                let sibling = sibling['parent']
            endwhile
        endif
        let skipFlag = 0
    endwhile
    if empty(target)
        return 0
    endif

    let t:ZFDirDiff_taskData['cursorState'] = ZFDirDiffAPI_parentPath(target) . target['name']
    call ZFDirDiffAPI_dataChangedImmediately(t:ZFDirDiff_taskData)
    return 1
endfunction

function! s:diffUI_diffJumpFileNext(cursorNode)
    let skipFlag = 0
    if empty(a:cursorNode)
        let toCheck = copy(t:ZFDirDiff_taskData['child'])
    else
        let toCheck = [a:cursorNode]
        if !ZFDirDiffAPI_diffNodeCanOpen(a:cursorNode)
            let skipFlag = 1
        endif
    endif

    let target = {}
    while !empty(toCheck)
        let check = remove(toCheck, 0)
        if !ZFDirDiffAPI_diffNodeCanOpen(check)
            if skipFlag
                let skipFlag = 0
            else
                if check['diff'] == 1
                    let target = check
                    break
                endif
            endif
        endif

        if ZFDirDiffAPI_diffNodeCanOpen(check) && !empty(check['child'])
            " search children
            call insert(toCheck, check['child'][0], 0)
        else
            " search and add next sibling
            let sibling = check
            while !empty(sibling['parent'])
                let childList = sibling['parent']['child']
                let index = ZFDirDiffAPI_diffNodeIndexUnsafe(childList, sibling)
                if index >= 0 && index < len(childList) - 1
                    call insert(toCheck, childList[index + 1], 0)
                    break
                endif
                let sibling = sibling['parent']
            endwhile
        endif
    endwhile
    if empty(target)
        return 0
    endif

    let t:ZFDirDiff_taskData['cursorState'] = ZFDirDiffAPI_parentPath(target) . target['name']
    call ZFDirDiffAPI_dataChangedImmediately(t:ZFDirDiff_taskData)
    return 1
endfunction

function! s:diffUI_op(taskData, diffNodes, op)
    let option = {}
    for diffNode in a:diffNodes
        call ZFDirDiffOp(a:taskData, diffNode, a:op, option)
        if option['confirm'] == 'q'
            break
        endif
    endfor
endfunction

" ============================================================
function! s:diffUI_makeKeymap()
    call s:makeKeymap('ZFDirDiffUIAction_update', 'ZFDirDiffKeymap_update', [])
    call s:makeKeymap('ZFDirDiffUIAction_updateParent', 'ZFDirDiffKeymap_updateParent', ['DD'])
    call s:makeKeymap('ZFDirDiffUIAction_open', 'ZFDirDiffKeymap_open', ['<cr>', 'o'])
    call s:makeKeymap('ZFDirDiffUIAction_foldOpenAll', 'ZFDirDiffKeymap_foldOpenAll', [])
    call s:makeKeymap('ZFDirDiffUIAction_foldOpenAllDiff', 'ZFDirDiffKeymap_foldOpenAllDiff', ['O'])
    call s:makeKeymap('ZFDirDiffUIAction_foldClose', 'ZFDirDiffKeymap_foldClose', ['x'])
    call s:makeKeymap('ZFDirDiffUIAction_foldCloseAll', 'ZFDirDiffKeymap_foldCloseAll', ['X'])
    call s:makeKeymap('ZFDirDiffUIAction_goParent', 'ZFDirDiffKeymap_goParent', ['U'])
    call s:makeKeymap('ZFDirDiffUIAction_diffThisDir', 'ZFDirDiffKeymap_diffThisDir', ['cd'])
    call s:makeKeymap('ZFDirDiffUIAction_diffParentDir', 'ZFDirDiffKeymap_diffParentDir', ['u'])
    call s:makeKeymap('ZFDirDiffUIAction_markToDiff', 'ZFDirDiffKeymap_markToDiff', ['DM'])
    call s:makeKeymap('ZFDirDiffUIAction_markToSync', 'ZFDirDiffKeymap_markToSync', ['DN'], 1)
    call s:makeKeymap('ZFDirDiffUIAction_quit', 'ZFDirDiffKeymap_quit', ['q'])
    call s:makeKeymap('ZFDirDiffUIAction_diffNext', 'ZFDirDiffKeymap_diffNext', [']c', 'DJ'])
    call s:makeKeymap('ZFDirDiffUIAction_diffPrev', 'ZFDirDiffKeymap_diffPrev', ['[c', 'DK'])
    call s:makeKeymap('ZFDirDiffUIAction_diffNextFile', 'ZFDirDiffKeymap_diffNextFile', ['Dj'])
    call s:makeKeymap('ZFDirDiffUIAction_diffPrevFile', 'ZFDirDiffKeymap_diffPrevFile', ['Dk'])
    call s:makeKeymap('ZFDirDiffUIAction_syncToHere', 'ZFDirDiffKeymap_syncToHere', ['do', 'DH'], 1)
    call s:makeKeymap('ZFDirDiffUIAction_syncToThere', 'ZFDirDiffKeymap_syncToThere', ['dp', 'DL'], 1)
    call s:makeKeymap('ZFDirDiffUIAction_add', 'ZFDirDiffKeymap_add', ['a'])
    call s:makeKeymap('ZFDirDiffUIAction_delete', 'ZFDirDiffKeymap_delete', ['dd'], 1)
    call s:makeKeymap('ZFDirDiffUIAction_getPath', 'ZFDirDiffKeymap_getPath', ['p'])
    call s:makeKeymap('ZFDirDiffUIAction_getFullPath', 'ZFDirDiffKeymap_getFullPath', ['P'])
endfunction

function! ZFDirDiffUIAction_update()
    if !exists('t:ZFDirDiff_taskData')
        echomsg '[ZFDirDiff] no previous diff task'
        return
    endif
    call s:diffUI_markClear()
    call ZFDirDiffAPI_update(t:ZFDirDiff_taskData)
endfunction

function! ZFDirDiffUIAction_updateParent()
    if !exists('t:ZFDirDiff_taskData')
        echomsg '[ZFDirDiff] no previous diff task'
        return
    endif
    call s:diffUI_markClear()
    let diffNode = ZFDirDiffUI_diffNodeUnderCursor()
    call ZFDirDiffAPI_update(t:ZFDirDiff_taskData, get(diffNode, 'parent', {}))
endfunction

function! ZFDirDiffUIAction_open()
    let diffNode = ZFDirDiffUI_diffNodeUnderCursor()
    if empty(diffNode)
        return
    endif
    if ZFDirDiffAPI_diffNodeCanOpen(diffNode)
        let diffNode['open'] = diffNode['open'] ? 0 : 1
        if diffNode['open']
            if get(g:, 'ZFDirDiffUI_autoOpenSingleChildDir', 1)
                while len(diffNode['child']) == 1
                            \ && ZFDirDiffAPI_diffNodeCanOpen(diffNode['child'][0])
                    let diffNode = diffNode['child'][0]
                    let diffNode['open'] = 1
                endwhile
            endif
        else
            let path = ZFDirDiffAPI_parentPath(diffNode) . diffNode['name']
            if exists("t:ZFDirDiff_taskData['openState'][path]")
                unlet t:ZFDirDiff_taskData['openState'][path]
            endif
        endif
        call ZFDirDiffAPI_dataChangedImmediately(t:ZFDirDiff_taskData)
        return
    endif
    if !ZFDirDiffAPI_diffNodeCanDiff(diffNode)
        echo '[ZFDirDiff] can not be compared: ' . ZFDirDiffAPI_parentPath(diffNode) . diffNode['name']
        return
    endif

    call s:fileDiffUI_start(
                \     tabpagenr()
                \   , diffNode
                \   , t:ZFDirDiff_taskData['fileL'] . ZFDirDiffAPI_parentPath(diffNode) . diffNode['name']
                \   , t:ZFDirDiff_taskData['fileR'] . ZFDirDiffAPI_parentPath(diffNode) . diffNode['name']
                \ )
endfunction

function! ZFDirDiffUIAction_foldOpenAll()
    if !exists('t:ZFDirDiff_taskData')
        echomsg '[ZFDirDiff] no previous diff task'
        return
    endif
    let diffNode = ZFDirDiffUI_diffNodeUnderCursor()
    if empty(diffNode)
        let diffNode = t:ZFDirDiff_taskData
    elseif !ZFDirDiffAPI_diffNodeCanOpen(diffNode)
        let diffNode = diffNode['parent']
    endif

    let queue = [diffNode]
    while !empty(queue)
        let diffNodeTmp = remove(queue, -1)
        call extend(queue, diffNodeTmp['child'])
        if ZFDirDiffAPI_diffNodeCanOpen(diffNodeTmp)
            let diffNodeTmp['open'] = 1
        endif
    endwhile

    call ZFDirDiffAPI_dataChangedImmediately(t:ZFDirDiff_taskData)
endfunction

function! ZFDirDiffUIAction_foldOpenAllDiff()
    if !exists('t:ZFDirDiff_taskData')
        echomsg '[ZFDirDiff] no previous diff task'
        return
    endif
    let diffNode = ZFDirDiffUI_diffNodeUnderCursor()
    if empty(diffNode)
        let diffNode = t:ZFDirDiff_taskData
    elseif !ZFDirDiffAPI_diffNodeCanOpen(diffNode)
        let diffNode = diffNode['parent']
    endif

    let queue = [diffNode]
    while !empty(queue)
        let diffNodeTmp = remove(queue, -1)
        call extend(queue, diffNodeTmp['child'])
        if ZFDirDiffAPI_diffNodeCanOpen(diffNodeTmp)
                    \ && diffNodeTmp['diff'] == 1
            let diffNodeTmp['open'] = 1
        endif
    endwhile

    call ZFDirDiffAPI_dataChangedImmediately(t:ZFDirDiff_taskData)
endfunction

function! ZFDirDiffUIAction_foldClose()
    let diffNode = ZFDirDiffUI_diffNodeUnderCursor()
    if empty(diffNode)
        return
    endif

    if !ZFDirDiffAPI_isTaskData(diffNode['parent'])
        let diffNode['parent']['open'] = 0
        let path = ZFDirDiffAPI_parentPath(diffNode['parent']) . diffNode['parent']['name']
        if exists("t:ZFDirDiff_taskData['openState'][path]")
            unlet t:ZFDirDiff_taskData['openState'][path]
        endif
        let t:ZFDirDiff_taskData['cursorState'] = ZFDirDiffAPI_parentPath(diffNode['parent']) . diffNode['parent']['name']
        call ZFDirDiffAPI_dataChangedImmediately(t:ZFDirDiff_taskData)
    endif
endfunction

function! ZFDirDiffUIAction_foldCloseAll()
    let toCheck = []
    call extend(toCheck, t:ZFDirDiff_taskData['child'])
    while !empty(toCheck)
        let diffNodeTmp = remove(toCheck, -1)
        if ZFDirDiffAPI_diffNodeCanOpen(diffNodeTmp)
            let diffNodeTmp['open'] = 0
            call extend(toCheck, diffNodeTmp['child'])
        endif
    endwhile

    let diffNode = ZFDirDiffUI_diffNodeUnderCursor()
    if !empty(diffNode)
        while !ZFDirDiffAPI_isTaskData(diffNode['parent'])
            let diffNode = diffNode['parent']
        endwhile
        let t:ZFDirDiff_taskData['cursorState'] = ZFDirDiffAPI_parentPath(diffNode) . diffNode['name']
        let t:ZFDirDiff_taskData['openState'] = {}
        call ZFDirDiffAPI_dataChangedImmediately(t:ZFDirDiff_taskData)
    else
        let t:ZFDirDiff_taskData['openState'] = {}
        call ZFDirDiffAPI_dataChangedImmediately(t:ZFDirDiff_taskData)
    endif
endfunction

function! ZFDirDiffUIAction_goParent()
    if !exists('t:ZFDirDiff_taskData')
        echomsg '[ZFDirDiff] no previous diff task'
        return
    endif
    call s:diffUI_start(
                \   fnamemodify(t:ZFDirDiff_taskData['fileL'], ':h'),
                \   fnamemodify(t:ZFDirDiff_taskData['fileR'], ':h')
                \ )
endfunction

function! ZFDirDiffUIAction_diffThisDir()
    let diffNode = ZFDirDiffUI_diffNodeUnderCursor()
    if empty(diffNode)
        return
    endif
    let parentPath = ZFDirDiffAPI_parentPath(diffNode)
    if bufnr('%') == t:ZFDirDiff_bufnrL
        let fileR = t:ZFDirDiff_taskData['fileR']
        let fileL = t:ZFDirDiff_taskData['fileL'] . parentPath . diffNode['name']
        if index([
                    \   g:ZFDirDiff_T_DIR,
                    \   g:ZFDirDiff_T_DIR_LEFT,
                    \   g:ZFDirDiff_T_CONFLICT_DIR_LEFT,
                    \ ], diffNode['type']) < 0
            let fileL = fnamemodify(fileL, ':h')
        endif
    else
        let fileL = t:ZFDirDiff_taskData['fileL']
        let fileR = t:ZFDirDiff_taskData['fileR'] . parentPath . diffNode['name']
        if index([
                    \   g:ZFDirDiff_T_DIR,
                    \   g:ZFDirDiff_T_DIR_RIGHT,
                    \   g:ZFDirDiff_T_CONFLICT_DIR_RIGHT,
                    \ ], diffNode['type']) < 0
            let fileR = fnamemodify(fileR, ':h')
        endif
    endif
    call s:diffUI_start(fileL, fileR)
endfunction

function! ZFDirDiffUIAction_diffParentDir()
    if !exists('t:ZFDirDiff_taskData')
        echomsg '[ZFDirDiff] no previous diff task'
        return
    endif
    if bufnr('%') == t:ZFDirDiff_bufnrL
        let fileL = fnamemodify(t:ZFDirDiff_taskData['fileL'], ':h')
        let fileR = t:ZFDirDiff_taskData['fileR']
    else
        let fileL = t:ZFDirDiff_taskData['fileL']
        let fileR = fnamemodify(t:ZFDirDiff_taskData['fileR'], ':h')
    endif
    call s:diffUI_start(fileL, fileR)
endfunction

function! ZFDirDiffUIAction_markToDiff()
    let diffNode = ZFDirDiffUI_diffNodeUnderCursor()
    if empty(diffNode)
        echo '[ZFDirDiff] no file or dir under cursor'
        return
    endif

    let bufnr = bufnr('%')
    let isLeft = (bufnr == t:ZFDirDiff_bufnrL)
    let parentPath = ZFDirDiffAPI_parentPath(diffNode)

    if !exists('t:ZFDirDiff_markToDiff')
        let t:ZFDirDiff_markToDiff = {
                    \   'bufnr' : bufnr,
                    \   'diffNode' : diffNode,
                    \ }
        call ZFDirDiffHLImpl_dataChanged(t:ZFDirDiff_taskData, bufnr)
        echo '[ZFDirDiff] mark again to diff with: '
                    \ . ZFDirDiffUI_bufLabel(a:isLeft)
                    \ . parentPath . diffNode['name']
        return
    endif

    if t:ZFDirDiff_markToDiff['bufnr'] == bufnr
                \ && ZFDirDiffAPI_diffNodeIsSame(diffNode, t:ZFDirDiff_markToDiff['diffNode'])
        unlet t:ZFDirDiff_markToDiff
        call ZFDirDiffHLImpl_dataChanged(t:ZFDirDiff_taskData, bufnr)
        echo '[ZFDirDiff] mark cleared'
        return
    endif

    let bufnrMarked = t:ZFDirDiff_markToDiff['bufnr']
    let diffNodeMarked = t:ZFDirDiff_markToDiff['diffNode']
    unlet t:ZFDirDiff_markToDiff
    let fileL = (bufnrMarked == t:ZFDirDiff_bufnrL
                \   ? t:ZFDirDiff_taskData['fileL']
                \   : t:ZFDirDiff_taskData['fileR']
                \ )
                \ . ZFDirDiffAPI_parentPath(diffNodeMarked) . diffNodeMarked['name']
    let fileR = (bufnr == t:ZFDirDiff_bufnrL
                \   ? t:ZFDirDiff_taskData['fileL']
                \   : t:ZFDirDiff_taskData['fileR']
                \ )
                \ . ZFDirDiffAPI_parentPath(diffNode) . diffNode['name']
    call ZFDirDiff(fileL, fileR)
endfunction

" mode: toggle/add/remove
" bufnr:
" * -1 : use current buffer
" * t:ZFDirDiff_bufnrL : use left buffer
" * t:ZFDirDiff_bufnrR : use right buffer
function! ZFDirDiffUIAction_markToSync(...) range
    call ZFDirDiffUIAction_markToSyncForRange(a:firstline, a:lastline, get(a:, 1, 'toggle'), get(a:, 2, -1))
    if exists('t:ZFDirDiff_taskData')
        call ZFDirDiffHLImpl_dataChanged(t:ZFDirDiff_taskData, bufnr('%'))
    endif
endfunction
function! ZFDirDiffUIAction_markToSyncForRange(first, last, ...)
    let mode = get(a:, 1, 'toggle')
    let bufnr = get(a:, 2, -1)
    let includeThereOnly = get(a:, 3, 0)

    if !exists('t:ZFDirDiff_taskData')
        echomsg '[ZFDirDiff] no previous diff task'
        return
    endif

    if bufnr != t:ZFDirDiff_bufnrL && bufnr != t:ZFDirDiff_bufnrR
        let bufnr = bufnr('%')
    endif
    let diffNodes = ZFDirDiffUI_diffNodesForRange(a:first, a:last, includeThereOnly ? -1 : bufnr)
    if empty(diffNodes)
        echo '[ZFDirDiff] no file or dir under cursor'
        return
    endif

    if !exists('t:ZFDirDiff_markToSync')
        let t:ZFDirDiff_markToSync = []
    endif
    for diffNode in diffNodes
        let exist = len(t:ZFDirDiff_markToSync) - 1
        while exist >= 0
            if t:ZFDirDiff_markToSync[exist]['bufnr'] == bufnr
                        \ && ZFDirDiffAPI_diffNodeIsSame(t:ZFDirDiff_markToSync[exist]['diffNode'], diffNode)
                break
            endif
            let exist -= 1
        endwhile
        if exist >= 0
            if mode != 'add'
                call remove(t:ZFDirDiff_markToSync, exist)
            endif
        else
            if mode != 'remove'
                call add(t:ZFDirDiff_markToSync, {
                            \   'bufnr' : bufnr,
                            \   'diffNode' : diffNode,
                            \ })
            endif
        endif
    endfor
    if empty(t:ZFDirDiff_markToSync)
        echo printf('[ZFDirDiff] mark cleared, %s again to mark to sync'
                    \ , join(ZFDirDiffUI_getKeymap('ZFDirDiffKeymap_markToSync'), '/')
                    \ )
    else
        echo printf('[ZFDirDiff] %d marked, %s %s %s to operate marked files, %s to clear marks'
                    \ , len(t:ZFDirDiff_markToSync)
                    \ , join(ZFDirDiffUI_getKeymap('ZFDirDiffKeymap_syncToHere'), '/')
                    \ , join(ZFDirDiffUI_getKeymap('ZFDirDiffKeymap_syncToThere'), '/')
                    \ , join(ZFDirDiffUI_getKeymap('ZFDirDiffKeymap_delete'), '/')
                    \ , join(ZFDirDiffUI_getKeymap('ZFDirDiffKeymap_update'), '/')
                    \ )
    endif
endfunction

function! ZFDirDiffUIAction_quit()
    if exists('t:ZFDirDiff_taskData')
        let taskData = t:ZFDirDiff_taskData
        call s:diffUI_tabDetach(tabpagenr(), t:ZFDirDiff_taskData)
        call ZFDirDiffAPI_cleanup(t:ZFDirDiff_taskData)
        call ZFDirDiffHLImpl_cleanup(taskData)
        unlet t:ZFDirDiff_taskData
    endif

    let ownerTab = t:ZFDirDiff_ownerTab

    while winnr('$') > 1
        let winCount = winnr('$')
        silent! bd!
        if winnr('$') == winCount
            break
        endif
    endwhile
    " delete again to delete last window
    silent! bd!

    execute 'normal! ' . ownerTab . 'gt'
endfunction

function! ZFDirDiffUIAction_diffNext()
    return s:diffUI_diffJump(1)
endfunction
function! ZFDirDiffUIAction_diffPrev()
    return s:diffUI_diffJump(0)
endfunction

function! ZFDirDiffUIAction_diffNextFile()
    return s:diffUI_diffJumpFile(1)
endfunction
function! ZFDirDiffUIAction_diffPrevFile()
    return s:diffUI_diffJumpFile(0)
endfunction

function! s:ZFDirDiffUIAction_syncToHereOrThere(first, last, syncToHere)
    if !exists('t:ZFDirDiff_taskData')
        echomsg '[ZFDirDiff] no previous diff task'
        return
    endif
    let bufnr = bufnr('%')
    if bufnr == t:ZFDirDiff_bufnrL
        if a:syncToHere
            let bufnrSrc = t:ZFDirDiff_bufnrR
            let op = 'r2l'
        else
            let bufnrSrc = t:ZFDirDiff_bufnrL
            let op = 'l2r'
        endif
    elseif bufnr == t:ZFDirDiff_bufnrR
        if a:syncToHere
            let bufnrSrc = t:ZFDirDiff_bufnrL
            let op = 'l2r'
        else
            let bufnrSrc = t:ZFDirDiff_bufnrR
            let op = 'r2l'
        endif
    else
        echomsg '[ZFDirDiff] invalid bufnr: ' . bufnr
                    \ . ', should be one of: '
                    \ . t:ZFDirDiff_bufnrL
                    \ . ' ' . t:ZFDirDiff_bufnrR
        return
    endif
    let diffNodes = ZFDirDiffUI_diffNodesForSync(a:first, a:last, bufnrSrc, 1)
    call s:diffUI_markClear()
    if empty(diffNodes)
        echo '[ZFDirDiff] no file or dir under cursor'
        return
    endif

    call s:diffUI_op(t:ZFDirDiff_taskData, diffNodes, op)
endfunction
function! ZFDirDiffUIAction_syncToHere() range
    call s:ZFDirDiffUIAction_syncToHereOrThere(a:firstline, a:lastline, 1)
endfunction
function! ZFDirDiffUIAction_syncToThere() range
    call s:ZFDirDiffUIAction_syncToHereOrThere(a:firstline, a:lastline, 0)
endfunction

function! ZFDirDiffUIAction_add()
    let diffNode = ZFDirDiffUI_diffNodeUnderCursor()
    if empty(diffNode)
        let diffNode = t:ZFDirDiff_taskData
    endif
    if empty(diffNode)
        echo '[ZFDirDiff] no file or dir under cursor'
        return
    endif

    let bufnr = bufnr('%')
    if bufnr == t:ZFDirDiff_bufnrL
        if ZFDirDiffAPI_isTaskData(diffNode)
            let fullParentPath = t:ZFDirDiff_taskData['fileL']
            let parentDiffNode = {}
        else
            let fullParentPath = t:ZFDirDiff_taskData['fileL'] . ZFDirDiffAPI_parentPath(diffNode) . diffNode['name']
            if index([
                        \   g:ZFDirDiff_T_DIR,
                        \   g:ZFDirDiff_T_DIR_LEFT,
                        \ ], diffNode['type']) >= 0
                let parentDiffNode = diffNode
            else
                let parentDiffNode = diffNode['parent']
                let fullParentPath = fnamemodify(fullParentPath, ':h')
            endif
        endif
    elseif bufnr == t:ZFDirDiff_bufnrR
        if ZFDirDiffAPI_isTaskData(diffNode)
            let fullParentPath = t:ZFDirDiff_taskData['fileR']
            let parentDiffNode = {}
        else
            let fullParentPath = t:ZFDirDiff_taskData['fileR'] . ZFDirDiffAPI_parentPath(diffNode) . diffNode['name']
            if index([
                        \   g:ZFDirDiff_T_DIR,
                        \   g:ZFDirDiff_T_DIR_RIGHT,
                        \ ], diffNode['type']) >= 0
                let parentDiffNode = diffNode
            else
                let parentDiffNode = diffNode['parent']
                let fullParentPath = fnamemodify(fullParentPath, ':h')
            endif
        endif
    else
        echomsg '[ZFDirDiff] invalid bufnr: ' . bufnr
                    \ . ', should be one of: '
                    \ . t:ZFDirDiff_bufnrL
                    \ . ' ' . t:ZFDirDiff_bufnrR
        return
    endif

    redraw!
    echo '[ZFDirDiff] input name/path of file/dir to add, end with `/` to add a dir'
    echo '    parent: ' . fullParentPath . '/'
    try
        let g:ZFDirDiffUI_inputFlag = 1
        let item = input('input: ')
    catch
    finally
        let g:ZFDirDiffUI_inputFlag = 0
    endtry
    redraw!

    if empty(item)
        return
    endif
    let isDir = (item[len(item) - 1] == '/' || item[len(item) - 1] == '\')
    let item = substitute(item, '^[/\\]\+', '', '')
    let item = substitute(item, '[/\\]\+$', '', '')
    if empty(item)
        return
    endif

    let fullPath = fullParentPath . '/' . item
    let fullPathAbs = ZFDirDiffAPI_pathFormat(fullPath)
    if isdirectory(fullPathAbs)
                \ || filereadable(fullPathAbs) || filewritable(fullPathAbs)
        echo '[ZFDirDiff] path already exist: ' . fullPath
        return
    endif

    if isDir
        call ZFDirDiffAPI_mkdir(fullPathAbs)
        redraw!
        echo '[ZFDirDiff] dir created: ' . fullPath
    else
        call ZFDirDiffAPI_mkdir(ZFDirDiffAPI_pathFormat(fullPath, ':h'))
        call writefile([], fullPathAbs)
        redraw!
        echo '[ZFDirDiff] file created: ' . fullPath
    endif

    if !empty(parentDiffNode) && !parentDiffNode['open']
        let parentDiffNode['open'] = 1
        call ZFDirDiffAPI_dataChangedImmediately(t:ZFDirDiff_taskData)
    endif
    if empty(parentDiffNode)
        let t:ZFDirDiff_taskData['cursorState'] = '/' . item
    else
        let t:ZFDirDiff_taskData['cursorState'] = ZFDirDiffAPI_parentPath(parentDiffNode) . parentDiffNode['name'] . '/' . item
    endif
    call ZFDirDiffAPI_update(t:ZFDirDiff_taskData, parentDiffNode)
endfunction

function! ZFDirDiffUIAction_delete() range
    if !exists('t:ZFDirDiff_taskData')
        echomsg '[ZFDirDiff] no previous diff task'
        return
    endif
    let bufnr = bufnr('%')
    if bufnr == t:ZFDirDiff_bufnrL
        let bufnrSrc = t:ZFDirDiff_bufnrL
        let op = 'dl'
    elseif bufnr == t:ZFDirDiff_bufnrR
        let bufnrSrc = t:ZFDirDiff_bufnrR
        let op = 'dr'
    else
        echomsg '[ZFDirDiff] invalid bufnr: ' . bufnr
                    \ . ', should be one of: '
                    \ . t:ZFDirDiff_bufnrL
                    \ . ' ' . t:ZFDirDiff_bufnrR
        return
    endif
    let diffNodes = ZFDirDiffUI_diffNodesForSync(a:firstline, a:lastline, bufnrSrc, 0)
    call s:diffUI_markClear()
    if empty(diffNodes)
        echo '[ZFDirDiff] no file or dir under cursor'
        return
    endif

    call s:diffUI_op(t:ZFDirDiff_taskData, diffNodes, op)
endfunction

function! s:ZFDirDiffUIAction_getPathOrFullPath(isFullPath)
    let diffNode = ZFDirDiffUI_diffNodeUnderCursor()
    if empty(diffNode)
        echo '[ZFDirDiff] no file or dir under cursor'
        return ''
    endif
    let bufnr = bufnr('%')
    if bufnr == t:ZFDirDiff_bufnrL
        let ignoreType = [
                    \   g:ZFDirDiff_T_DIR_RIGHT,
                    \   g:ZFDirDiff_T_FILE_RIGHT,
                    \ ]
        let fileLorR = t:ZFDirDiff_taskData['fileL']
    elseif bufnr == t:ZFDirDiff_bufnrR
        let ignoreType = [
                    \   g:ZFDirDiff_T_DIR_LEFT,
                    \   g:ZFDirDiff_T_FILE_LEFT,
                    \ ]
        let fileLorR = t:ZFDirDiff_taskData['fileR']
    endif
    if index(ignoreType, diffNode['type']) >= 0
        echo '[ZFDirDiff] no file or dir under cursor'
        return ''
    endif

    let path = ZFDirDiffAPI_parentPath(diffNode) . diffNode['name']
    if a:isFullPath
        let path = fileLorR . path
    endif
    if has('clipboard')
        let @*=path
    else
        let @"=path
    endif
    return path
endfunction
function! ZFDirDiffUIAction_getPath()
    let path = s:ZFDirDiffUIAction_getPathOrFullPath(0)
    if !empty(path)
        echo '[ZFDirDiff] copied path: ' . path
    endif
endfunction
function! ZFDirDiffUIAction_getFullPath()
    let path = s:ZFDirDiffUIAction_getPathOrFullPath(1)
    if !empty(path)
        echo '[ZFDirDiff] copied full path: ' . path
    endif
endfunction

" ============================================================
" tab local var:
" * t:ZFDirDiff_fileDiff_bufnrL : bufnr of left file
" * t:ZFDirDiff_fileDiff_bufnrR : bufnr of right file
"
" optional tab local var:
"     // invalid if started from plain file diff
"     // typical case: fileL/fileR are both file when `:ZFDirDiff fileL fileR`
" * t:ZFDirDiff_ownerDiffTab : start from which diff tab, maybe -1
" * t:ZFDirDiff_ownerDiffNode : start from which diffNode, maybe {}
function! s:fileDiffUI_start(ownerDiffTab, ownerDiffNode, pathL, pathR)
    execute 'tabedit ' . substitute(a:pathL, ' ', '\\ ', 'g')

    let t:ZFDirDiff_ownerDiffTab = a:ownerDiffTab
    let t:ZFDirDiff_ownerDiffNode = a:ownerDiffNode

    let t:ZFDirDiff_fileDiff_bufnrL = bufnr('%')
    diffthis
    call s:fileDiffUI_makeKeymap()

    vsplit

    wincmd l
    wincmd k
    enew
    execute 'edit ' . substitute(a:pathR, ' ', '\\ ', 'g')
    let t:ZFDirDiff_fileDiff_bufnrR = bufnr('%')
    diffthis
    call s:fileDiffUI_makeKeymap()

    wincmd =
endfunction

function! s:fileDiffUI_askWrite(isLeft)
    if !&modified
        return 0
    endif
    redraw
    let hint = printf("%s\n    %s\n\nfile modified, save?"
                \ , ZFDirDiffUI_bufLabel(a:isLeft)
                \ , expand("%:p")
                \ )
    let input = confirm(hint, "&Yes\n&No", 1)
    if input == 1
        silent w!
        return 1
    else
        return 0
    endif
endfunction

" ============================================================
function! s:fileDiffUI_makeKeymap()
    call s:makeKeymap('ZFDirDiffUIAction_quitFileDiff', 'ZFDirDiffKeymap_quitFileDiff', ['q'])
endfunction

function! ZFDirDiffUIAction_quitFileDiff()
    let ownerDiffTab = t:ZFDirDiff_ownerDiffTab
    let taskData = gettabvar(ownerDiffTab, 'ZFDirDiff_taskData')
    let diffNode = t:ZFDirDiff_ownerDiffNode
    let modified = 0

    call ZFDirDiffUI_jumpWin(t:ZFDirDiff_fileDiff_bufnrL, 1)
    execute 'b' . t:ZFDirDiff_fileDiff_bufnrL
    if s:fileDiffUI_askWrite(1)
        let modified = 1
    endif

    call ZFDirDiffUI_jumpWin(t:ZFDirDiff_fileDiff_bufnrR, 0)
    execute 'b' . t:ZFDirDiff_fileDiff_bufnrR
    if s:fileDiffUI_askWrite(0)
        let modified = 1
    endif

    let tabnr = tabpagenr('$')
    while tabpagenr('$') > 1 && exists('t:ZFDirDiff_ownerDiffTab') && tabnr == tabpagenr('$')
        bd!
    endwhile

    if ownerDiffTab != -1
        silent! execute 'silent! normal! ' . ownerDiffTab . 'gt'
        if !empty(taskData) && modified
            call ZFDirDiffAPI_update(taskData, diffNode['parent'])
        else
            " UI won't update when tab not in foreground
            " update manually
            call ZFDirDiffAPI_dataChangedImmediately(taskData)
        endif
    endif
endfunction

