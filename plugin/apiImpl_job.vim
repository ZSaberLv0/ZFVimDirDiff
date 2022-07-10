
" this key would be used in each diffNode,
" use short form to save some memory
let s:KEY_jobIdMap = 'Ijm'

" taskData: {
"   ...
"
"   'child' : [
"     {
"       'type' : xxx,
"       ...
"
"       s:KEY_jobIdMap : { // list file/dir or diff task id of this diffNode
"         '<jobId>' : 1,
"       },
"     },
"   ],
"
"   s:KEY_jobIdMap : { // list file/dir or diff task id of all of child
"     '<jobId>' : 1,
"   },
" }
function! ZFDirDiffAPIImpl_job_init(taskData)
    if !exists('*ZFJobAvailable')
        echomsg '[ZFDirDiff] depends on ZFJobTimerAvailable()'
        echomsg '    please install ZSaberLv0/ZFVimJob'
        return {}
    endif
    if !ZFJobTimerAvailable()
        echomsg '[ZFDirDiff] depends on ZFJobTimerAvailable()'
        echomsg '    try put "let g:ZFJobTimerFallback=1" to your vimrc'
        return {}
    endif

    return a:taskData
endfunction

function! ZFDirDiffAPIImpl_job_cleanup(taskData)
    call s:stopAllTask(a:taskData)
endfunction

function! ZFDirDiffAPIImpl_job_update(taskData, ...)
    call s:update(a:taskData, get(a:, 1, {}))
endfunction

" ============================================================
" diffNode can be taskData or child diffNode
function! s:stopAllTask(diffNode)
    let toStop = [a:diffNode]
    while !empty(toStop)
        let diffNode = remove(toStop, 0)
        call extend(toStop, get(diffNode, 'child', []))

        let jobIdMap = get(diffNode, s:KEY_jobIdMap, {})
        if empty(jobIdMap)
            continue
        endif
        let diffNode[s:KEY_jobIdMap] = {}
        for jobId in keys(jobIdMap)
            call ZFGroupJobStop(jobId)
        endfor
    endwhile
endfunction

function! s:update(taskData, diffNode)
    if empty(a:diffNode) || ZFDirDiffAPI_isTaskData(a:diffNode)
        call s:updateAll(a:taskData)
    else
        call s:stopAllTask(a:diffNode)
        call s:listChild(a:taskData, a:diffNode)
    endif
endfunction

function! s:updateAll(taskData)
    call s:stopAllTask(a:taskData)
    call s:listChild(a:taskData, a:taskData)
endfunction

" ============================================================
" parentDiffNode can be taskData or diffNode
" return 1 if any child job started
function! s:listChild(taskData, parentDiffNode)
    let parentPath = ZFDirDiffAPI_parentPath(a:parentDiffNode)
    if !ZFDirDiffAPI_isTaskData(a:parentDiffNode)
        let parentPath .= a:parentDiffNode['name'] . '/'
    endif
    " <name, side>
    " side: -1: left, 1: right, 0: both
    " conflict contains the side of dir type
    let listChildData = {
                \   'dir' : {},
                \   'file' : {},
                \   'conflict' : {},
                \ }
    let jobList = []

    if isdirectory(a:taskData['pathL'] . parentPath)
        call add(jobList, {
                    \   'jobCmd' : ZFDirDiffCmd_listDir(a:taskData['pathL'] . parentPath),
                    \   'onOutput' : ZFJobFunc(function('ZFDirDiffAPIImpl_job_listChild_onOutput'), [listChildData, 1, 1]),
                    \ })
        call add(jobList, {
                    \   'jobCmd' : ZFDirDiffCmd_listFile(a:taskData['pathL'] . parentPath),
                    \   'onOutput' : ZFJobFunc(function('ZFDirDiffAPIImpl_job_listChild_onOutput'), [listChildData, 0, 1]),
                    \ })
    endif
    if isdirectory(a:taskData['pathR'] . parentPath)
        call add(jobList, {
                    \   'jobCmd' : ZFDirDiffCmd_listDir(a:taskData['pathR'] . parentPath),
                    \   'onOutput' : ZFJobFunc(function('ZFDirDiffAPIImpl_job_listChild_onOutput'), [listChildData, 1, 0]),
                    \ })
        call add(jobList, {
                    \   'jobCmd' : ZFDirDiffCmd_listFile(a:taskData['pathR'] . parentPath),
                    \   'onOutput' : ZFJobFunc(function('ZFDirDiffAPIImpl_job_listChild_onOutput'), [listChildData, 0, 0]),
                    \ })
    endif

    if empty(jobList)
        return 0
    endif

    if !ZFDirDiffAPI_isTaskData(a:parentDiffNode)
        let parentTmp = a:parentDiffNode
        while !empty(parentTmp)
            let parentTmp['diff'] = -1
            let parentTmp = parentTmp['parent']
        endwhile
    endif

    let jobId = ZFGroupJobStart({
                \   'jobList' : [jobList],
                \   'onExit' : ZFJobFunc(function('ZFDirDiffAPIImpl_job_listChild_onExit'), [a:taskData, a:parentDiffNode, listChildData]),
                \   'groupJobStopOnChildError' : 0,
                \ })
    if jobId > 0
        if !exists("a:parentDiffNode[s:KEY_jobIdMap]")
            let a:parentDiffNode[s:KEY_jobIdMap] = {}
        endif
        let a:parentDiffNode[s:KEY_jobIdMap][jobId] = 1
        return 1
    else
        return 0
    endif
endfunction

function! s:listChildRecursive(taskData, parentDiffNode)
    let hasChildJob = 0
    for child in a:parentDiffNode['child']
        if child['type'] == g:ZFDirDiff_T_DIR
                    \ || child['type'] == g:ZFDirDiff_T_DIR_LEFT
                    \ || child['type'] == g:ZFDirDiff_T_DIR_RIGHT
            if s:listChild(a:taskData, child)
                let hasChildJob = 1
            endif
        endif
    endfor
    return hasChildJob
endfunction

function! ZFDirDiffAPIImpl_job_listChild_onOutput(listChildData, isDir, isLeft, jobStatus, textList, type)
    if a:type == 'stderr'
        return
    endif

    let side = a:isLeft ? -1 : 1
    if a:isDir
        for name in a:textList
            let name = fnamemodify(name, ':t')
            if empty(name)
                continue
            endif
            if exists("a:listChildData['file'][name]")
                unlet a:listChildData['file'][name]
                let a:listChildData['conflict'][name] = side
            elseif exists("a:listChildData['dir'][name]")
                if a:listChildData['dir'][name] + side == 0
                    let a:listChildData['dir'][name] = 0
                endif
            else
                let a:listChildData['dir'][name] = side
            endif
        endfor
    else
        for name in a:textList
            let name = fnamemodify(name, ':t')
            if empty(name)
                continue
            endif
            if exists("a:listChildData['dir'][name]")
                unlet a:listChildData['dir'][name]
                let a:listChildData['conflict'][name] = 0 - side
            elseif exists("a:listChildData['file'][name]")
                if a:listChildData['file'][name] + side == 0
                    let a:listChildData['file'][name] = 0
                endif
            else
                let a:listChildData['file'][name] = side
            endif
        endfor
    endif
endfunction

function! ZFDirDiffAPIImpl_job_listChild_onExit(taskData, parentDiffNode, listChildData, jobStatus, exitCode)
    if exists("a:parentDiffNode[s:KEY_jobIdMap][a:jobStatus['jobId']]")
        unlet a:parentDiffNode[s:KEY_jobIdMap][a:jobStatus['jobId']]
    endif

    if a:exitCode == g:ZFJOBSTOP
        return
    endif

    call ZFDirDiffAPI_stateSave(a:taskData, {
                \   'openState' : 1,
                \   'cursorState' : empty(a:taskData['cursorState']) ? 1 : 0,
                \ })

    if !ZFDirDiffAPI_isTaskData(a:parentDiffNode)
        let parent = a:parentDiffNode
    else
        let parent = {}
    endif

    let childHasDiff = 0
    let childNeedDiff = 0

    let childList = []
    for name in sort(keys(a:listChildData['dir']), 1)
        if ZFDirDiff_excludeCheck(a:taskData, a:parentDiffNode, name)
            continue
        endif
        let side = a:listChildData['dir'][name]
        let diffNode = {
                    \   'parent' : parent,
                    \   'name' : name,
                    \   'open' : 0,
                    \   'child' : [],
                    \ }
        if side == 0
            let childNeedDiff = 1
            let diffNode['type'] = g:ZFDirDiff_T_DIR
            let diffNode['diff'] = -1
        elseif side == -1
            let childHasDiff = 1
            let diffNode['type'] = g:ZFDirDiff_T_DIR_LEFT
            let diffNode['diff'] = 1
        elseif side == 1
            let childHasDiff = 1
            let diffNode['type'] = g:ZFDirDiff_T_DIR_RIGHT
            let diffNode['diff'] = 1
        else
        endif
        call add(childList, diffNode)
    endfor
    for name in sort(keys(a:listChildData['conflict']), 1)
        if ZFDirDiff_excludeCheck(a:taskData, a:parentDiffNode, name)
            continue
        endif
        let side = a:listChildData['conflict'][name]
        let diffNode = {
                    \   'parent' : parent,
                    \   'name' : name,
                    \   'open' : 0,
                    \   'child' : [],
                    \ }
        if side == 0
            continue
        elseif side == -1
            let childHasDiff = 1
            let diffNode['type'] = g:ZFDirDiff_T_CONFLICT_DIR_LEFT
            let diffNode['diff'] = 1
        elseif side == 1
            let childHasDiff = 1
            let diffNode['type'] = g:ZFDirDiff_T_CONFLICT_DIR_RIGHT
            let diffNode['diff'] = 1
        else
        endif
        call add(childList, diffNode)
    endfor
    for name in sort(keys(a:listChildData['file']), 1)
        if ZFDirDiff_excludeCheck(a:taskData, a:parentDiffNode, name)
            continue
        endif
        let side = a:listChildData['file'][name]
        let diffNode = {
                    \   'parent' : parent,
                    \   'name' : name,
                    \   'open' : 0,
                    \   'child' : [],
                    \ }
        if side == 0
            let childNeedDiff = 1
            let diffNode['type'] = g:ZFDirDiff_T_SAME
            let diffNode['diff'] = -1
        elseif side == -1
            let childHasDiff = 1
            let diffNode['type'] = g:ZFDirDiff_T_FILE_LEFT
            let diffNode['diff'] = 1
        elseif side == 1
            let childHasDiff = 1
            let diffNode['type'] = g:ZFDirDiff_T_FILE_RIGHT
            let diffNode['diff'] = 1
        else
        endif
        call add(childList, diffNode)
    endfor

    let a:parentDiffNode['child'] = childList

    let hasChildJob = 0
    if childNeedDiff || childHasDiff
        if s:diffChild(a:taskData, a:parentDiffNode)
            let hasChildJob = 1
        endif
    endif

    if !hasChildJob
        call s:listChildRecursive(a:taskData, a:parentDiffNode)
        call ZFDirDiffAPI_diffUpdate(a:parentDiffNode)
    endif
    call ZFDirDiffAPI_dataChanged(a:taskData)
endfunction

" ============================================================
" return 1 if any diff job started
function! s:diffChild(taskData, parentDiffNode)
    let parentPath = ZFDirDiffAPI_parentPath(a:parentDiffNode)
    if !ZFDirDiffAPI_isTaskData(a:parentDiffNode)
        let parentPath .= a:parentDiffNode['name'] . '/'
    endif
    let jobList = []
    for child in a:parentDiffNode['child']
        if child['diff'] != -1 || child['type'] == g:ZFDirDiff_T_DIR
            continue
        endi
        call add(jobList, {
                    \   'jobCmd' : ZFDirDiffCmd_diff(
                    \       a:taskData['pathL'] . parentPath . child['name'],
                    \       a:taskData['pathR'] . parentPath . child['name']
                    \   ),
                    \   'onExit' : ZFJobFunc(function('ZFDirDiffAPIImpl_diffChild_child_onExit'), [child]),
                    \ })
    endfor
    if empty(jobList)
        return 0
    endif

    let jobId = ZFGroupJobStart({
                \   'jobList' : [jobList],
                \   'onExit' : ZFJobFunc(function('ZFDirDiffAPIImpl_diffChild_onExit'), [a:taskData, a:parentDiffNode]),
                \   'groupJobStopOnChildError' : 0,
                \ })
    if jobId > 0
        if !exists("a:parentDiffNode[s:KEY_jobIdMap]")
            let a:parentDiffNode[s:KEY_jobIdMap] = {}
        endif
        let a:parentDiffNode[s:KEY_jobIdMap][jobId] = 1
        return 1
    else
        return 0
    endif
endfunction

function! ZFDirDiffAPIImpl_diffChild_child_onExit(diffNode, jobStatus, exitCode)
    if a:exitCode == g:ZFJOBSTOP
        return
    endif

    if a:exitCode == 0
        let a:diffNode['type'] = g:ZFDirDiff_T_SAME
        let a:diffNode['diff'] = 0
    else
        let a:diffNode['type'] = g:ZFDirDiff_T_DIFF
        let a:diffNode['diff'] = 1
    endif
endfunction

function! ZFDirDiffAPIImpl_diffChild_onExit(taskData, parentDiffNode, jobStatus, exitCode)
    if exists("a:parentDiffNode[s:KEY_jobIdMap][a:jobStatus['jobId']]")
        unlet a:parentDiffNode[s:KEY_jobIdMap][a:jobStatus['jobId']]
    endif
    if a:exitCode == g:ZFJOBSTOP
        return
    endif
    call ZFDirDiffAPI_diffUpdate(a:parentDiffNode)
    call ZFDirDiffAPI_stateSave(a:taskData, {
                \   'openState' : 1,
                \   'cursorState' : empty(a:taskData['cursorState']) ? 1 : 0,
                \ })
    call ZFDirDiffAPI_dataChanged(a:taskData)
    call s:listChildRecursive(a:taskData, a:parentDiffNode)
endfunction

