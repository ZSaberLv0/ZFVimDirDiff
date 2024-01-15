
" ============================================================
if !exists('g:ZFDirDiffUI_showSameFile')
    let g:ZFDirDiffUI_showSameFile = 1
endif

if !exists('g:ZFDirDiffUI_showSameDir')
    let g:ZFDirDiffUI_showSameDir = 1
endif

if !exists('g:ZFDirDiff_ignoreEmptyDir')
    let g:ZFDirDiff_ignoreEmptyDir = 1
endif

if !exists('g:ZFDirDiff_ignoreSpace')
    let g:ZFDirDiff_ignoreSpace = 0
endif

if !exists('*ZFDirDiff_excludeCheck')
    " return 1 if excluded, which means the item should not be diff-ed
    function! ZFDirDiff_excludeCheck(taskData, diffNode)
        if exists('*ZFIgnoreGet')
            return ZFDirDiff_excludeCheck_ZFIgnore(a:taskData, a:diffNode)
        else
            return ZFDirDiff_excludeCheck_fallback(a:taskData, a:diffNode)
        endif
    endfunction
endif

" ============================================================
" T_DIR,T_SAME,T_DIFF,T_DIR_LEFT,T_DIR_RIGHT,T_FILE_LEFT,T_FILE_RIGHT,T_CONFLICT_DIR_LEFT,T_CONFLICT_DIR_RIGHT
let g:ZFDirDiff_T_DIR = 'DD' " both dir
let g:ZFDirDiff_T_FILE = 'FF' " both file
let g:ZFDirDiff_T_DIR_LEFT = 'D-' " left is dir, right not exist
let g:ZFDirDiff_T_DIR_RIGHT = '-D' " right is dir, left not exist
let g:ZFDirDiff_T_FILE_LEFT = 'F-' " left is file, right not exist
let g:ZFDirDiff_T_FILE_RIGHT = '-F' " right is file, left not exist
let g:ZFDirDiff_T_CONFLICT_DIR_LEFT = 'DF' " left is dir, right is file
let g:ZFDirDiff_T_CONFLICT_DIR_RIGHT = 'FD' " left is file, right is dir

if !exists('*ZFDirDiffAPI_typeHint')
    function! ZFDirDiffAPI_typeHint(diffNode)
        if 0
        elseif a:diffNode['type'] == g:ZFDirDiff_T_DIR
            if a:diffNode['diff'] == -1
                return 'DU'
            elseif a:diffNode['diff'] == 1
                return 'dd'
            else
                return 'DD'
            endif
        elseif a:diffNode['type'] == g:ZFDirDiff_T_FILE
            if a:diffNode['diff'] == -1
                return 'FU'
            elseif a:diffNode['diff'] == 1
                return 'ff'
            else
                return 'FF'
            endif
        elseif a:diffNode['type'] == g:ZFDirDiff_T_DIR_LEFT
            return 'D-'
        elseif a:diffNode['type'] == g:ZFDirDiff_T_DIR_RIGHT
            return '-D'
        elseif a:diffNode['type'] == g:ZFDirDiff_T_FILE_LEFT
            return 'F-'
        elseif a:diffNode['type'] == g:ZFDirDiff_T_FILE_RIGHT
            return '-F'
        elseif a:diffNode['type'] == g:ZFDirDiff_T_CONFLICT_DIR_LEFT
            return 'DF'
        elseif a:diffNode['type'] == g:ZFDirDiff_T_CONFLICT_DIR_RIGHT
            return 'FD'
        else
            return printf('<%s>', a:diffNode['type'])
        endif
    endfunction
endif

" start dir diff session, return taskData: {
"   'fileL' : 'orig fileL',
"   'fileR' : 'orig fileR',
"   'pathL' : 'abs path of fileL',
"   'pathR' : 'abs path of fileR',
"
"   'diff' : -1/0/1,
"   'parent' : {}, // ensured empty for taskData
"   'child' : [ // each diffNode of child
"     {
"       'parent' : {...}, // parent node, link to taskData for top level item
"       'name' : 'file name of the node',
"
"       'type' : 'type of the node, see g:ZFDirDiff_T_DIR series',
"       'diff' : -1/0/1, // -1 : still checking
"                        // 0 : this node and all of its child is same
"                        // 1 : this node or any of its child has diff
"
"       'open' : 0/1, // valid for T_DIR types, 1 if the dir has opened
"       'child' : [ // valid for T_DIR types, child diff
"         {
"           't' : '...',
"           ...,
"         },
"         ...
"       ],
"     },
"     ...
"   ],
"
"   'headerLen' : N, // header length in linesL/linesR
"   'tailLen' : N, // tail length in linesL/linesR
"   'linesL' : [...], // raw content to display as buffer
"   'linesR' : [...],
"   'childVisible' : [...], // visible diffNode for each line, ensured same count with linesL/linesR
"   'cursorLine' : 0, // recommended cursor line to restore, 0 means no need change
"                     // UI impl should:
"                     //     1. read this value during cbDataChanged
"                     //     2. update cursor line
"                     //     3. reset this value to 0 when done
"
"   'option' : {...},
"
"   'openState' : {}, // a dict of <path, dummy> that needs to be opened during ZFDirDiffAPI_dataChanged
"                     // format: '/xxx/xxx'
"                     // typically saved by ZFDirDiffAPI_openStateSave
"                     // match logic:
"                     // * all dir type diffNode that `match(keys(openState), '^.' . parentPath . diffNode['name'])` would be opened
"                     // * when something exactly matched openState,
"                     //   the matched rule would be removed from openState after ZFDirDiffAPI_dataChanged
"   'cursorState' : '', // a path that needs to restore cursor during ZFDirDiffUI_cbDataChanged
"                       // format: '/xxx/xxx'
"                       // typically saved by ZFDirDiffAPI_cursorStateSave
"                       // cursor should be restored by UI accorrding to taskData['cursorLine']
"
"   'DEBUG' : {
"     'updateStartTime' : localtime(), // last update start time
"     'updateCostTime' : localtime() - updateStartTime, // -1 if still updating
"   },
" }
"
" option: {
"   'cbDataChanged' : function(), // (required) called when `child/linesL/linesR/childVisible` changed
"   'cbHeader' : function(taskData), // (optional) called to obtain header lines, return: {
"                                    //   'headerL' : [],
"                                    //   'headerR' : [],
"                                    // }
"   'cbTail' : function(taskData), // (optional) called to obtain tail lines, return: {
"                                  //   'tailL' : [],
"                                  //   'tailR' : [],
"                                  // }
"   'cbDiffLine' : function(taskData, diffNode, depth, isLeft, isDir), // (optional) called to display each diff line
" }
function! ZFDirDiffAPI_init(fileL, fileR, option)
    if empty(get(a:option, 'cbDataChanged', ''))
        echomsg '[ZFDirDiff] invalid option'
        return {}
    endif

    let fileL = s:pathNormalize(a:fileL)
    let fileR = s:pathNormalize(a:fileR)
    let taskData = {
                \   'fileL' : fileL,
                \   'fileR' : fileR,
                \   'pathL' : ZFDirDiffAPI_pathFormat(fileL),
                \   'pathR' : ZFDirDiffAPI_pathFormat(fileR),
                \   'diff' : -1,
                \   'parent' : {},
                \   'child' : [],
                \   'headerLen' : 0,
                \   'tailLen' : 0,
                \   'linesL' : [],
                \   'linesR' : [],
                \   'childVisible' : [],
                \   'cursorLine' : 0,
                \   'option' : a:option,
                \   'openState' : {},
                \   'cursorState' : '',
                \   'DEBUG' : {
                \     'updateStartTime' : localtime(),
                \     'updateCostTime' : -1,
                \   },
                \ }
    return ZFDirDiffAPIImpl_init(taskData)
endfunction
function! s:pathNormalize(path)
    let path = a:path
    let path = substitute(path, '\\', '/', 'g')
    let path = substitute(path, '//\+', '/', 'g')
    let path = substitute(path, '/\+$', '', '')
    if empty(path)
        let path = '.'
    endif
    return path
endfunction

function! ZFDirDiffAPI_cleanup(taskData)
    if !exists("a:taskData['fileL']")
        echomsg '[ZFDirDiff] invalid taskData'
        return
    endif
    call ZFDirDiffAPIImpl_cleanup(a:taskData)
    unlet a:taskData['fileL']
    if get(a:taskData, '_updateDelayId', -1) != -1
        call ZFJobTimerStop(a:taskData['_updateDelayId'])
        let a:taskData['_updateDelayId'] = -1
    endif
    if get(a:taskData, '_dataChangedDelayId', -1) != -1
        call ZFJobTimerStop(a:taskData['_dataChangedDelayId'])
        let a:taskData['_dataChangedDelayId'] = -1
    endif
endfunction

" if diffNode supplied, update specified file/dir
" otherwise, update entire dir
function! ZFDirDiffAPI_update(taskData, ...)
    if !exists("a:taskData['fileL']")
        echomsg '[ZFDirDiff] invalid taskData'
        return
    endif
    if get(a:taskData, '_updateDelayId', -1) != -1
        return
    endif
    let a:taskData['_updateDelayId'] = ZFJobTimerStart(
                \ get(g:, 'ZFDirDiff_updateDelay', 500),
                \ ZFJobFunc(function('ZFDirDiffAPI_updateDelayCallback'), [a:taskData, get(a:, 1, {})]))
endfunction
function! ZFDirDiffAPI_updateDelayCallback(taskData, diffNode, ...)
    let a:taskData['_updateDelayId'] = -1
    call ZFDirDiffAPIImpl_update(a:taskData, a:diffNode)
endfunction
function! ZFDirDiffAPI_updateImmediately(taskData, ...)
    if get(a:taskData, '_updateDelayId', -1) != -1
        call ZFJobTimerStop(a:taskData['_updateDelayId'])
        let a:taskData['_updateDelayId'] = -1
    endif
    call ZFDirDiffAPIImpl_update(a:taskData, a:diffNode)
endfunction

" save state which would automatically restored during ZFDirDiffAPI_dataChanged
function! ZFDirDiffAPI_openStateSave(taskData)
    let toCheck = []
    call extend(toCheck, a:taskData['child'])
    while !empty(toCheck)
        let diffNode = remove(toCheck, 0)
        if ZFDirDiffAPI_diffNodeCanOpen(diffNode)
            if diffNode['open']
                let a:taskData['openState'][ZFDirDiffAPI_parentPath(diffNode) . diffNode['name']] = 1
                call extend(toCheck, diffNode['child'])
            endif
        endif
    endwhile
endfunction

function! ZFDirDiffAPI_cursorStateSave(taskData)
    let a:taskData['cursorState'] = ''
    let index = line('.') - 1
    if index >= 0 && index < len(a:taskData['childVisible'])
        let cursorNode = a:taskData['childVisible'][index]
        if !empty(cursorNode)
            let a:taskData['cursorState'] = ZFDirDiffAPI_parentPath(cursorNode) . cursorNode['name']
        endif
    endif
endfunction

function! ZFDirDiffAPI_dataChanged(taskData)
    " speed up first screen
    if !empty(a:taskData['child'])
                \ && len(a:taskData['childVisible']) == a:taskData['headerLen'] + a:taskData['tailLen']
        call ZFDirDiffAPI_dataChangedImmediately(a:taskData)
        return
    endif

    if get(a:taskData, '_dataChangedDelayId', -1) != -1
        return
    endif
    let a:taskData['_dataChangedDelayId'] = ZFJobTimerStart(
                \ get(g:, 'ZFDirDiff_updateDelay', 500),
                \ ZFJobFunc(function('ZFDirDiffAPI_dataChangedDelayCallback'), [a:taskData]))
endfunction
function! ZFDirDiffAPI_dataChangedDelayCallback(taskData, ...)
    let a:taskData['_dataChangedDelayId'] = -1
    call ZFDirDiffAPI_dataChangedImmediately(a:taskData)
endfunction
function! ZFDirDiffAPI_dataChangedImmediately(taskData)
    if !exists("a:taskData['fileL']")
        echomsg '[ZFDirDiff] invalid taskData'
        return
    endif
    if get(a:taskData, '_dataChangedDelayId', -1) != -1
        call ZFJobTimerStop(a:taskData['_dataChangedDelayId'])
        let a:taskData['_dataChangedDelayId'] = -1
    endif

    call ZFDirDiffAPI_openStateSave(a:taskData)
    if empty(a:taskData['cursorState'])
        call ZFDirDiffAPI_cursorStateSave(a:taskData)
    endif

    let a:taskData['headerLen'] = 0
    let a:taskData['tailLen'] = 0
    let a:taskData['linesL'] = []
    let a:taskData['linesR'] = []
    let a:taskData['childVisible'] = []

    " restore state
    call s:dataChanged_openStateRestore(a:taskData)
    let cursorNode = s:dataChanged_cursorStateRestore(a:taskData)

    " header
    let Fn_cbHeader = get(a:taskData['option'], 'cbHeader', '')
    if !empty(Fn_cbHeader)
        let header = Fn_cbHeader(a:taskData)
        call extend(a:taskData['linesL'], header['headerL'])
        call extend(a:taskData['linesR'], header['headerR'])
        while len(a:taskData['linesL']) < len(a:taskData['linesR'])
            call add(a:taskData['linesL'], '')
        endwhile
        while len(a:taskData['linesR']) < len(a:taskData['linesL'])
            call add(a:taskData['linesR'], '')
        endwhile
        let a:taskData['headerLen'] = len(a:taskData['linesL'])
        while len(a:taskData['childVisible']) < len(a:taskData['linesL'])
            call add(a:taskData['childVisible'], {})
        endwhile
    endif

    " each lines
    for diffNode in a:taskData['child']
        call s:dataChanged_linesAdd(a:taskData, diffNode, 0)
    endfor

    " tail
    let Fn_cbTail = get(a:taskData['option'], 'cbTail', '')
    if !empty(Fn_cbTail)
        let tail = Fn_cbTail(a:taskData)
        call extend(a:taskData['linesL'], tail['tailL'])
        call extend(a:taskData['linesR'], tail['tailR'])
        while len(a:taskData['linesL']) < len(a:taskData['linesR'])
            call add(a:taskData['linesL'], '')
        endwhile
        while len(a:taskData['linesR']) < len(a:taskData['linesL'])
            call add(a:taskData['linesR'], '')
        endwhile
        let a:taskData['tailLen'] = len(a:taskData['linesL'])
        while len(a:taskData['childVisible']) < len(a:taskData['linesL'])
            call add(a:taskData['childVisible'], {})
        endwhile
    else
        " by default, add an empty tail line for convenient
        let a:taskData['tailLen'] = 1
        call add(a:taskData['linesL'], '')
        call add(a:taskData['linesR'], '')
        call add(a:taskData['childVisible'], {})
    endif

    " restore cursor
    if !empty(cursorNode)
        let i = a:taskData['headerLen']
        let iEnd = len(a:taskData['childVisible']) - a:taskData['tailLen']
        while i < iEnd
            if ZFDirDiffAPI_diffNodeIsSame(a:taskData['childVisible'][i], cursorNode)
                let a:taskData['cursorLine'] = i + 1
                break
            endif
            let i += 1
        endwhile
    endif

    let Fn_cbDataChanged = a:taskData['option']['cbDataChanged']
    call Fn_cbDataChanged()
    redraw!

    if a:taskData['diff'] != -1 && a:taskData['DEBUG']['updateCostTime'] == -1
        let a:taskData['DEBUG']['updateCostTime'] = localtime() - a:taskData['DEBUG']['updateStartTime']
    endif
endfunction

function! s:dataChanged_openStateRestore(taskData)
    if empty(get(a:taskData, 'openState', {}))
        return
    endif
    let openState = a:taskData['openState']
    let toCheck = []
    call extend(toCheck, a:taskData['child'])
    let openStateKeys = keys(openState)
    while !empty(toCheck) && !empty(openStateKeys)
        let diffNode = remove(toCheck, 0)
        if diffNode['type'] != g:ZFDirDiff_T_DIR
                    \ && diffNode['type'] != g:ZFDirDiff_T_DIR_LEFT
                    \ && diffNode['type'] != g:ZFDirDiff_T_DIR_RIGHT
            continue
        endif
        call extend(toCheck, diffNode['child'])
        let path = ZFDirDiffAPI_parentPath(diffNode) . diffNode['name']

        let index = -1
        let indexTmp = len(openStateKeys) - 1
        while indexTmp >= 0
            if openStateKeys[indexTmp] == path
                let index = indexTmp
                break
            endif
            let indexTmp -= 1
        endwhile
        if index < 0
            continue
        endif

        let diffNode['open'] = 1
        unlet openState[openStateKeys[index]]
        let openStateKeys = keys(openState)
    endwhile
endfunction
function! s:dataChanged_cursorStateRestore(taskData)
    if empty(get(a:taskData, 'cursorState', ''))
        return {}
    endif
    let cursorState = a:taskData['cursorState']
    let target = {}
    let toCheck = []
    call extend(toCheck, a:taskData['child'])
    while !empty(toCheck)
        let diffNode = remove(toCheck, 0)
        let path = ZFDirDiffAPI_parentPath(diffNode) . diffNode['name']
        let index = match(cursorState, '^' . path)
        if index < 0
            continue
        endif
        if cursorState == path
            let target = diffNode
            let a:taskData['cursorState'] = ''
            break
        endif
        call extend(toCheck, diffNode['child'])
    endwhile
    if empty(target)
        return {}
    endif
    let diffNode = target['parent']
    while !empty(diffNode)
        let diffNode['open'] = 1
        let diffNode = diffNode['parent']
    endwhile
    return target
endfunction
function! s:dataChanged_linesAdd(taskData, diffNode, depth)
    if empty(get(a:taskData['option'], 'cbDiffLine', {}))
        let Fn_cbDiffLine = function('ZFDirDiffUI_cbDiffLineDefault')
    else
        let Fn_cbDiffLine = a:taskData['option']['cbDiffLine']
    endif

    if 0
    elseif a:diffNode['type'] == g:ZFDirDiff_T_DIR
        if g:ZFDirDiffUI_showSameDir || a:diffNode['diff']
            call add(a:taskData['childVisible'], a:diffNode)
            call add(a:taskData['linesL'], Fn_cbDiffLine(a:taskData, a:diffNode, a:depth, 1, 1))
            call add(a:taskData['linesR'], Fn_cbDiffLine(a:taskData, a:diffNode, a:depth, 0, 1))
            call s:dataChanged_linesAddChild(a:taskData, a:diffNode, a:depth)
        endif
    elseif a:diffNode['type'] == g:ZFDirDiff_T_FILE
        if g:ZFDirDiffUI_showSameFile || a:diffNode['diff']
            call add(a:taskData['childVisible'], a:diffNode)
            call add(a:taskData['linesL'], Fn_cbDiffLine(a:taskData, a:diffNode, a:depth, 1, 0))
            call add(a:taskData['linesR'], Fn_cbDiffLine(a:taskData, a:diffNode, a:depth, 0, 0))
        endif
    elseif a:diffNode['type'] == g:ZFDirDiff_T_DIR_LEFT
        call add(a:taskData['childVisible'], a:diffNode)
        call add(a:taskData['linesL'], Fn_cbDiffLine(a:taskData, a:diffNode, a:depth, 1, 1))
        call add(a:taskData['linesR'], Fn_cbDiffLine(a:taskData, a:diffNode, a:depth, 0, -1))
        call s:dataChanged_linesAddChild(a:taskData, a:diffNode, a:depth)
    elseif a:diffNode['type'] == g:ZFDirDiff_T_DIR_RIGHT
        call add(a:taskData['childVisible'], a:diffNode)
        call add(a:taskData['linesL'], Fn_cbDiffLine(a:taskData, a:diffNode, a:depth, 1, -1))
        call add(a:taskData['linesR'], Fn_cbDiffLine(a:taskData, a:diffNode, a:depth, 0, 1))
        call s:dataChanged_linesAddChild(a:taskData, a:diffNode, a:depth)
    elseif a:diffNode['type'] == g:ZFDirDiff_T_FILE_LEFT
        call add(a:taskData['childVisible'], a:diffNode)
        call add(a:taskData['linesL'], Fn_cbDiffLine(a:taskData, a:diffNode, a:depth, 1, 0))
        call add(a:taskData['linesR'], Fn_cbDiffLine(a:taskData, a:diffNode, a:depth, 0, -1))
    elseif a:diffNode['type'] == g:ZFDirDiff_T_FILE_RIGHT
        call add(a:taskData['childVisible'], a:diffNode)
        call add(a:taskData['linesL'], Fn_cbDiffLine(a:taskData, a:diffNode, a:depth, 1, -1))
        call add(a:taskData['linesR'], Fn_cbDiffLine(a:taskData, a:diffNode, a:depth, 0, 0))
    elseif a:diffNode['type'] == g:ZFDirDiff_T_CONFLICT_DIR_LEFT
        call add(a:taskData['childVisible'], a:diffNode)
        call add(a:taskData['linesL'], Fn_cbDiffLine(a:taskData, a:diffNode, a:depth, 1, 1))
        call add(a:taskData['linesR'], Fn_cbDiffLine(a:taskData, a:diffNode, a:depth, 0, 0))
    elseif a:diffNode['type'] == g:ZFDirDiff_T_CONFLICT_DIR_RIGHT
        call add(a:taskData['childVisible'], a:diffNode)
        call add(a:taskData['linesL'], Fn_cbDiffLine(a:taskData, a:diffNode, a:depth, 1, 0))
        call add(a:taskData['linesR'], Fn_cbDiffLine(a:taskData, a:diffNode, a:depth, 0, 1))
    endif
endfunction
function! s:dataChanged_linesAddChild(taskData, diffNode, depth)
    if a:diffNode['open']
        for child in a:diffNode['child']
            call s:dataChanged_linesAdd(a:taskData, child, a:depth + 1)
        endfor
    endif
endfunction

" ZFDirDiffAPI_diffUpdate(diffNode[, recursive])
function! ZFDirDiffAPI_diffUpdate(diffNode, ...)
    if ZFDirDiffAPI_isTaskData(a:diffNode) || a:diffNode['type'] == g:ZFDirDiff_T_DIR
        let diff = 0
        for child in a:diffNode['child']
            if child['diff'] == -1
                let diff = -1
                break
            elseif child['diff'] == 1
                let diff = 1
            endif
        endfor
    elseif a:diffNode['type'] == g:ZFDirDiff_T_FILE
        let diff = a:diffNode['diff']
    else
        let diff = 1
    endif
    if a:diffNode['diff'] != diff
        let a:diffNode['diff'] = diff
        if get(a:, 1, 1)
            let diffNode = a:diffNode['parent']
            while !empty(diffNode)
                call ZFDirDiffAPI_diffUpdate(diffNode, 0)
                let diffNode = diffNode['parent']
            endwhile
        endif
    endif
endfunction

function! ZFDirDiffAPI_isTaskData(diffNode)
    return !empty(get(a:diffNode, 'pathL', ''))
endfunction

function! ZFDirDiffAPI_diffNodeIndexUnsafe(childList, diffNode)
    let i = len(a:childList) - 1
    while i >= 0
        let child = a:childList[i]
        if child['type'] == a:diffNode['type']
                    \ && child['name'] == a:diffNode['name']
            return i
        endif
        let i -= 1
    endwhile
    return -1
endfunction

function! ZFDirDiffAPI_diffNodeIsSame(diffNode0, diffNode1)
    if ZFDirDiffAPI_isTaskData(a:diffNode0)
        return ZFDirDiffAPI_isTaskData(a:diffNode0)
    else
        return !ZFDirDiffAPI_isTaskData(a:diffNode0) && (
                    \      a:diffNode0['type'] == a:diffNode1['type']
                    \   && a:diffNode0['name'] == a:diffNode1['name']
                    \   && ZFDirDiffAPI_diffNodeIsSame(a:diffNode0['parent'], a:diffNode1['parent'])
                    \   )
    endif
endfunction

let s:typeList_canOpen = [
            \   g:ZFDirDiff_T_DIR,
            \   g:ZFDirDiff_T_DIR_LEFT,
            \   g:ZFDirDiff_T_DIR_RIGHT,
            \ ]
let s:typeList_canDiff = [
            \   g:ZFDirDiff_T_FILE,
            \   g:ZFDirDiff_T_FILE_LEFT,
            \   g:ZFDirDiff_T_FILE_RIGHT,
            \ ]
function! ZFDirDiffAPI_diffNodeCanOpen(diffNode)
    return index(s:typeList_canOpen, get(a:diffNode, 'type', g:ZFDirDiff_T_FILE)) >= 0
endfunction
function! ZFDirDiffAPI_diffNodeCanDiff(diffNode)
    return index(s:typeList_canDiff, get(a:diffNode, 'type', g:ZFDirDiff_T_CONFLICT_DIR_LEFT)) >= 0
endfunction

" useful to debug taskData['childVisible']
function! ZFDirDiffAPI_diffNodesInfo(diffNodes)
    let ret = []
    for diffNode in a:diffNodes
        call add(ret, s:diffNodeInfo(diffNode, ''))
    endfor
    return ret
endfunction

function! ZFDirDiffAPI_diffNodeTreeInfo(diffNode)
    let ret = []
    if ZFDirDiffAPI_isTaskData(a:diffNode)
        let prefix = ''
    else
        call add(ret, s:diffNodeInfo(a:diffNode, ''))
        let prefix = '    '
    endif
    for child in a:diffNode['child']
        call s:diffNodeTreeInfo(ret, child, prefix)
    endfor
    return ret
endfunction
function! s:diffNodeTreeInfo(ret, diffNode, prefix)
    call add(a:ret, s:diffNodeInfo(a:diffNode, a:prefix))
    let prefix = a:prefix . '    '
    for child in a:diffNode['child']
        call s:diffNodeTreeInfo(a:ret, child, prefix)
    endfor
endfunction

function! s:diffNodeInfo(diffNode, prefix)
    if empty(a:diffNode) || ZFDirDiffAPI_isTaskData(a:diffNode)
        return ''
    else
        return a:prefix
                    \ . (ZFDirDiffAPI_diffNodeCanOpen(a:diffNode)
                    \     ? (a:diffNode['open'] ? '~ ' : '+ ')
                    \     : '  '
                    \ )
                    \ . ZFDirDiffAPI_typeHint(a:diffNode)
                    \ . ' ' . ZFDirDiffAPI_parentPath(a:diffNode) . a:diffNode['name']
                    \ . (ZFDirDiffAPI_diffNodeCanOpen(a:diffNode) ? '/' : '')
    endif
endfunction

" ============================================================
function! CygpathFix_absPath(path)
    if len(a:path) <= 0|return ''|endif
    if !exists('g:CygpathFix_isCygwin')
        let g:CygpathFix_isCygwin = has('win32unix') && executable('cygpath')
    endif
    let path = fnamemodify(a:path, ':p')
    if !empty(path) && g:CygpathFix_isCygwin
        if 0 " cygpath is really slow
            let path = substitute(system('cygpath -m "' . path . '"'), '[\r\n]', '', 'g')
        else
            if match(path, '^/cygdrive/') >= 0
                let path = toupper(strpart(path, len('/cygdrive/'), 1)) . ':' . strpart(path, len('/cygdrive/') + 1)
            else
                if !exists('g:CygpathFix_cygwinPrefix')
                    let g:CygpathFix_cygwinPrefix = substitute(system('cygpath -m /'), '[\r\n]', '', 'g')
                endif
                let path = g:CygpathFix_cygwinPrefix . path
            endif
        endif
    endif
    return substitute(substitute(path, '\\', '/', 'g'), '\%(\/\)\@<!\/\+$', '', '') " (?<!\/)\/+$
endfunction

" ensured return '/' for top level diffNode, and '/some/path/' for children
" so it's convenient to concat full path by:
"     taskData['pathL'] . parentPath . diffNode['name']
" specially, when passed taskData as diffNode, '/' would be returned
function! ZFDirDiffAPI_parentPath(diffNode)
    let parentPath = '/'
    let diffNode = a:diffNode['parent']
    while !empty(diffNode) && !ZFDirDiffAPI_isTaskData(diffNode)
        let parentPath = '/' . diffNode['name'] . parentPath
        let diffNode = diffNode['parent']
    endwhile
    return parentPath
endfunction

" return depth of the diffNode, top level diffNode has 0 depth
function! ZFDirDiffAPI_depth(diffNode)
    let depth = 0
    let diffNode = a:diffNode
    while !ZFDirDiffAPI_isTaskData(diffNode['parent'])
        let diffNode = diffNode['parent']
        let depth += 1
    endwhile
    return depth
endfunction

function! ZFDirDiffAPI_pathFormat(path, ...)
    let path = a:path
    let path = CygpathFix_absPath(path)
    if !empty(get(a:, 1, ''))
        let mod_path = fnamemodify(path, a:1)
        if get(a:, 1, '') == ':.' && path != mod_path
            " If relative path under cwd, then prefix with . to show it's
            " relative.
            let mod_path = './' . mod_path
        endif
        let path = mod_path
    endif
    let path = substitute(path, '\\$\|/$', '', '')
    return substitute(path, '\\', '/', 'g')
endfunction

function! ZFDirDiffAPI_pathHint(path, ...)
    if isdirectory(a:path)
        return ZFDirDiffAPI_pathFormat(a:path, get(a:, 1, '')) . '/'
    else
        return ZFDirDiffAPI_pathFormat(a:path, get(a:, 1, ''))
    endif
endfunction

" ============================================================
if !exists('*ZFDirDiffAPI_mkdir')
    function! ZFDirDiffAPI_mkdir(path)
        if exists("*mkdir")
            call mkdir(a:path, 'p')
        elseif (has('win32') || has('win64')) && !has('unix')
            silent execute '!mkdir "' . substitute(a:path, '/', '\', 'g') . '"'
        else
            silent execute '!mkdir -p "' . a:path . '"'
        endif
    endfunction
endif

if !exists('*ZFDirDiffAPI_cpfile')
    function! ZFDirDiffAPI_cpfile(from, to)
        call ZFDirDiffAPI_mkdir(fnamemodify(a:to, ":h"))
        if (has('win32') || has('win64')) && !has('unix')
            silent execute '!copy "' . substitute(a:from, '/', '\', 'g') . '" "' . substitute(a:to, '/', '\', 'g') . '"'
        else
            silent execute '!cp -rf "' . a:from . '" "' . a:to . '"'
        endif
    endfunction
endif

if !exists('*ZFDirDiffAPI_rmdir')
    function! ZFDirDiffAPI_rmdir(path)
        if (has('win32') || has('win64')) && !has('unix')
            silent execute '!rmdir /s/q "' . substitute(a:path, '/', '\', 'g') . '"'
        else
            silent execute '!rm -rf "' . a:path . '"'
        endif
    endfunction
endif

if !exists('*ZFDirDiffAPI_rmfile')
    function! ZFDirDiffAPI_rmfile(path)
        if (has('win32') || has('win64')) && !has('unix')
            silent execute '!del /f/q "' . substitute(a:path, '/', '\', 'g') . '"'
        else
            silent execute '!rm -f "' . a:path . '"'
        endif
    endfunction
endif

