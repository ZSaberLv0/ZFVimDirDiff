
highlight default link ZFDirDiffHL_Header Title
highlight default link ZFDirDiffHL_Tail Title
highlight default link ZFDirDiffHL_DirChecking SpecialKey
highlight default link ZFDirDiffHL_DirSame Folded
highlight default link ZFDirDiffHL_DirDiff DiffChange
highlight default link ZFDirDiffHL_FileChecking SpecialKey
highlight default link ZFDirDiffHL_FileSame Folded
highlight default link ZFDirDiffHL_FileDiff DiffText
highlight default link ZFDirDiffHL_DirOnlyHere DiffAdd
highlight default link ZFDirDiffHL_FileOnlyHere DiffAdd
highlight default link ZFDirDiffHL_ConflictDirHere ErrorMsg
highlight default link ZFDirDiffHL_ConflictDirThere WarningMsg
highlight default link ZFDirDiffHL_MarkToDiff Cursor
highlight default link ZFDirDiffHL_MarkToSync Cursor

" ============================================================
" extra impl data attached to taskData: {
"   'HLImpl' : {
"     'tabpagenr' : tabpagenr,
"     'needUpdateL' : 0/1,
"     'matchIdsL' : [], // a list of ids returned by s:hlLineAdd
"     'startL' : N, // first highlighted line number, start from 1
"                   // startL + len(matchIdsL) should be the window's height
"                   // otherwise, it means the highlight should be updated
"     'needUpdateR' : 0/1,
"     'matchIdsR' : [],
"     'startR' : N,
"   },
" }
function! ZFDirDiffHLImpl_init(taskData, ...)
    let tabpagenr = get(a:, 1, -1)
    if tabpagenr < 0
        let tabpagenr = tabpagenr()
    endif
    let a:taskData['HLImpl'] = {
                \   'tabpagenr' : tabpagenr,
                \   'needUpdateL' : 1,
                \   'matchIdsL' : [],
                \   'startL' : 0,
                \   'needUpdateR' : 1,
                \   'matchIdsR' : [],
                \   'startR' : 0,
                \ }
    execute 'augroup ZFDirDiffHLImpl_augroup_' . tabpagenr
    autocmd!
    autocmd CursorMoved * call s:redrawDelayed(0)
    execute 'augroup END'
endfunction

function! ZFDirDiffHLImpl_cleanup(taskData)
    execute 'augroup ZFDirDiffHLImpl_augroup_' . a:taskData['HLImpl']['tabpagenr']
    autocmd!
    execute 'augroup END'
    noautocmd call s:cleanup(a:taskData)
endfunction
function! s:cleanup(taskData)
    call ZFDirDiffUI_jumpWin(t:ZFDirDiff_bufnrL, 1)
    call clearmatches()
    let a:taskData['HLImpl']['matchIdsL'] = []
    let a:taskData['HLImpl']['startL'] = 0

    call ZFDirDiffUI_jumpWin(t:ZFDirDiff_bufnrR, 0)
    call clearmatches()
    let a:taskData['HLImpl']['matchIdsR'] = []
    let a:taskData['HLImpl']['startR'] = 0
endfunction

" bufnr : specify buf to update, or -1 to update both
function! ZFDirDiffHLImpl_dataChanged(taskData, ...)
    let bufnr = get(a:, 1, -1)
    let tabpagenr = a:taskData['HLImpl']['tabpagenr']
    let bufnrL = gettabvar(tabpagenr, 'ZFDirDiff_bufnrL')
    let bufnrR = gettabvar(tabpagenr, 'ZFDirDiff_bufnrR')
    if bufnr == bufnrL
        let a:taskData['HLImpl']['needUpdateL'] = 1
    elseif bufnr == bufnrR
        let a:taskData['HLImpl']['needUpdateR'] = 1
    else
        let a:taskData['HLImpl']['needUpdateL'] = 1
        let a:taskData['HLImpl']['needUpdateR'] = 1
    endif
    call s:redrawDelayed(1)
endfunction

" ============================================================
function! s:redrawDelayed(forceUpdate)
    if exists('s:redrawFlag')
        return
    endif

    if !a:forceUpdate
        if !exists('t:ZFDirDiff_taskData')
            return
        endif
        let bufnr = bufnr('%')
        let HLImpl = t:ZFDirDiff_taskData['HLImpl']
        if bufnr == t:ZFDirDiff_bufnrL
            if !HLImpl['needUpdateL'] && line('w0') == HLImpl['startL']
                return
            endif
        elseif bufnr == t:ZFDirDiff_bufnrR
            if !HLImpl['needUpdateR'] && line('w0') == HLImpl['startR']
                return
            endif
        else
            return
        endif
    endif

    if !exists('s:redrawDelayedTaskId')
        let s:redrawDelayedTaskId = ZFJobTimerStart(
                    \ get(g:, 'ZFDirDiffHL_delay', 100)
                    \ , function('ZFDirDiffHLImpl_redrawDelayedCallback'))
    endif
endfunction
function! ZFDirDiffHLImpl_redrawDelayedCallback(...)
    unlet s:redrawDelayedTaskId
    noautocmd call s:redrawAction()
endfunction

augroup ZFDirDiffHLImpl_CmdWin_augroup
    autocmd!
    if !exists('s:cmdFlag')
        let s:cmdFlag = 0
    endif
    if exists('##CmdlineEnter')
        autocmd CmdlineEnter * let s:cmdFlag += 1
        autocmd CmdlineLeave * let s:cmdFlag -= 1
    endif
    autocmd CmdwinEnter * let s:cmdFlag += 1
    autocmd CmdwinLeave * let s:cmdFlag -= 1
augroup END

function! s:redrawAction()
    if !exists('t:ZFDirDiff_taskData')
                \ || exists('s:redrawFlag')
                \ || s:cmdFlag
        return
    endif
    try
        let s:redrawFlag = 1
        let bufnr = bufnr('%')
        let winnr = winnr()
        let tabpagenr = t:ZFDirDiff_taskData['HLImpl']['tabpagenr']
        let bufnrL = gettabvar(tabpagenr, 'ZFDirDiff_bufnrL')
        let bufnrR = gettabvar(tabpagenr, 'ZFDirDiff_bufnrR')

        call ZFDirDiffUI_jumpWin(t:ZFDirDiff_bufnrL, 1)
        if bufnr('%') == bufnrL
            call s:redrawBuf(t:ZFDirDiff_taskData, tabpagenr, bufnrL, bufnrL, bufnrR)
        endif

        call ZFDirDiffUI_jumpWin(t:ZFDirDiff_bufnrR, 0)
        if bufnr('%') == bufnrR
            call s:redrawBuf(t:ZFDirDiff_taskData, tabpagenr, bufnrR, bufnrL, bufnrR)
        endif

        if bufnr == bufnrL
            call ZFDirDiffUI_jumpWin(t:ZFDirDiff_bufnrL, 1)
        else
            execute winnr . 'wincmd w'
        endif
    finally
        unlet s:redrawFlag
    endtry
    if !get(g:, 'ZFDirDiffUI_inputFlag', 0)
        redraw
    endif
endfunction

function! s:redrawBuf(taskData, tabpagenr, bufnr, bufnrL, bufnrR)
    " check
    if a:bufnr == a:bufnrL
        let k_needUpdate = 'needUpdateL'
        let k_matchIds = 'matchIdsL'
        let k_start = 'startL'
    else
        let k_needUpdate = 'needUpdateR'
        let k_matchIds = 'matchIdsR'
        let k_start = 'startR'
    endif
    let winFirst = line('w0')
    let winLast = line('w$')
    let hlFirst = a:taskData['HLImpl'][k_start]
    let hlLast = hlFirst + len(a:taskData['HLImpl'][k_matchIds]) - 1
    if !a:taskData['HLImpl'][k_needUpdate]
                \ && winFirst == hlFirst
                \ && winLast == hlLast
        return
    endif

    " cleanup
    for matchId in a:taskData['HLImpl'][k_matchIds]
        try
            silent! call matchdelete(matchId)
        catch
        endtry
    endfor
    let a:taskData['HLImpl'][k_matchIds] = []
    let a:taskData['HLImpl'][k_start] = 0

    " prepare highlight
    let i = winFirst - 1
    if i >= len(a:taskData['childVisible'])
        return
    endif
    let iEnd = winLast - 1
    if iEnd >= len(a:taskData['childVisible'])
        let iEnd = len(a:taskData['childVisible']) - 1
    endif
    let a:taskData['HLImpl'][k_needUpdate] = 0
    let a:taskData['HLImpl'][k_start] = winFirst

    " header
    while i < a:taskData['headerLen']
        let i += 1
        call s:hlLineAdd(a:taskData['HLImpl'][k_matchIds], {}, 'ZFDirDiffHL_Header', i)
    endwhile

    " tail
    let iTail = len(a:taskData['childVisible']) - a:taskData['tailLen']
    while iEnd >= iTail
        call s:hlLineAdd(a:taskData['HLImpl'][k_matchIds], {}, 'ZFDirDiffHL_Tail', iEnd + 1)
        let iEnd -= 1
    endwhile

    " each diff line
    if !empty(gettabvar(a:tabpagenr, 'ZFDirDiff_markToDiff'))
        let ZFDirDiff_markToDiff = gettabvar(a:tabpagenr, 'ZFDirDiff_markToDiff')
    else
        let ZFDirDiff_markToDiff = {}
    endif
    if !empty(gettabvar(a:tabpagenr, 'ZFDirDiff_markToSync'))
        let ZFDirDiff_markToSync = gettabvar(a:tabpagenr, 'ZFDirDiff_markToSync')
    else
        let ZFDirDiff_markToSync = []
    endif
    while i <= iEnd
        let child = a:taskData['childVisible'][i]
        let i += 1
        if empty(child)
            continue
        endif

        let markToDiff = (get(ZFDirDiff_markToDiff, 'bufnr', -1) == a:bufnr)
                    \ && ZFDirDiffAPI_diffNodeIsSame(ZFDirDiff_markToDiff['diffNode'], child)
        let markToSync = 0
        let iMarkToSync = len(ZFDirDiff_markToSync) - 1
        while iMarkToSync >= 0
            if ZFDirDiff_markToSync[iMarkToSync]['bufnr'] == a:bufnr
                        \ && ZFDirDiffAPI_diffNodeIsSame(ZFDirDiff_markToSync[iMarkToSync]['diffNode'], child)
                let markToSync = 1
                break
            endif
            let iMarkToSync -= 1
        endwhile

        let hlGroup = ''
        if markToSync
            let hlGroup = 'ZFDirDiffHL_MarkToSync'
        elseif markToDiff
            let hlGroup = 'ZFDirDiffHL_MarkToDiff'
        elseif child['type'] == g:ZFDirDiff_T_DIR
            if child['diff'] == -1
                let hlGroup = 'ZFDirDiffHL_DirChecking'
            elseif child['diff'] == 1
                let hlGroup = 'ZFDirDiffHL_DirDiff'
            else
                let hlGroup = 'ZFDirDiffHL_DirSame'
            endif
        elseif child['type'] == g:ZFDirDiff_T_FILE
            if child['diff'] == -1
                let hlGroup = 'ZFDirDiffHL_FileChecking'
            elseif child['diff'] == 1
                let hlGroup = 'ZFDirDiffHL_FileDiff'
            else
                let hlGroup = 'ZFDirDiffHL_FileSame'
            endif
        elseif child['type'] == g:ZFDirDiff_T_DIR_LEFT
            if a:bufnr == a:bufnrL
                let hlGroup = 'ZFDirDiffHL_DirOnlyHere'
            endif
        elseif child['type'] == g:ZFDirDiff_T_DIR_RIGHT
            if a:bufnr == a:bufnrR
                let hlGroup = 'ZFDirDiffHL_DirOnlyHere'
            endif
        elseif child['type'] == g:ZFDirDiff_T_FILE_LEFT
            if a:bufnr == a:bufnrL
                let hlGroup = 'ZFDirDiffHL_FileOnlyHere'
            endif
        elseif child['type'] == g:ZFDirDiff_T_FILE_RIGHT
            if a:bufnr == a:bufnrR
                let hlGroup = 'ZFDirDiffHL_FileOnlyHere'
            endif
        elseif child['type'] == g:ZFDirDiff_T_CONFLICT_DIR_LEFT
            if a:bufnr == a:bufnrL
                let hlGroup = 'ZFDirDiffHL_ConflictDirHere'
            else
                let hlGroup = 'ZFDirDiffHL_ConflictDirThere'
            endif
        elseif child['type'] == g:ZFDirDiff_T_CONFLICT_DIR_RIGHT
            if a:bufnr == a:bufnrR
                let hlGroup = 'ZFDirDiffHL_ConflictDirHere'
            else
                let hlGroup = 'ZFDirDiffHL_ConflictDirThere'
            endif
        endif

        if !empty(hlGroup)
            call s:hlLineAdd(a:taskData['HLImpl'][k_matchIds], child, hlGroup, i)
        endif
    endwhile
endfunction

" ============================================================
function! s:hlLineAdd(matchIds, diffNode, hlGroup, line)
    if !empty(a:diffNode)
        let line = getline(a:line)
        let name = a:diffNode['name']
        let index = stridx(line, name)
        if index >= 0
            call add(a:matchIds, matchadd(a:hlGroup, '\%' . a:line . 'l'
                        \   . '\%>' . index . 'c'
                        \   . '\%<' . (index + len(name) + 1) . 'c'
                        \ ))
            return
        endif
    endif
    call add(a:matchIds, matchadd(a:hlGroup, '\%' . a:line . 'l'))
endfunction

