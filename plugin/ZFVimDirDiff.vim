" ============================================================
" options
" ============================================================

" dir diff buffer filetype
if !exists('g:ZFDirDiffUI_filetypeLeft')
    let g:ZFDirDiffUI_filetypeLeft = 'ZFDirDiffLeft'
endif
if !exists('g:ZFDirDiffUI_filetypeRight')
    let g:ZFDirDiffUI_filetypeRight = 'ZFDirDiffRight'
endif

" tabstop of the diff buffer
if !exists('g:ZFDirDiffUI_tabstop')
    let g:ZFDirDiffUI_tabstop = 2
endif

if !exists('g:ZFDirDiffUI_dirExpandable')
    let g:ZFDirDiffUI_dirExpandable = '+'
endif
if !exists('g:ZFDirDiffUI_dirCollapsible')
    let g:ZFDirDiffUI_dirCollapsible = '~'
endif

" when > 0, fold items whose level greater than this value
if !exists('g:ZFDirDiffUI_foldlevel')
    let g:ZFDirDiffUI_foldlevel = 0
endif

if !exists('g:ZFDirDiffUI_foldDirOnly')
    let g:ZFDirDiffUI_foldDirOnly = 1
endif

" autocmd
augroup ZF_DirDiff_augroup
    autocmd!
    autocmd User ZFDirDiff_DirDiffEnter silent
    autocmd User ZFDirDiff_FileDiffEnter silent
augroup END

" function name to get the header text
"     YourFunc()
" return a list of string
"   Use b:ZFDirDiff_isLeft, b:ZFDirDiff_fileLeft, b:ZFDirDiff_fileRight to
"   build your header
if !exists('g:ZFDirDiffUI_headerTextFunc')
    let g:ZFDirDiffUI_headerTextFunc = 'ZF_DirDiff_headerText'
endif
function! ZF_DirDiff_headerText()
    let text = []
    if b:ZFDirDiff_isLeft
        call add(text, '[LEFT]: ' . ZF_DirDiffPathFormat(t:ZFDirDiff_fileLeft, ':~') . '/')
        call add(text, '[LEFT]: ' . ZF_DirDiffPathFormat(t:ZFDirDiff_fileLeft, ':.') . '/')
    else
        call add(text, '[RIGHT]: ' . ZF_DirDiffPathFormat(t:ZFDirDiff_fileRight, ':~') . '/')
        call add(text, '[RIGHT]: ' . ZF_DirDiffPathFormat(t:ZFDirDiff_fileRight, ':.') . '/')
    endif
    call add(text, '------------------------------------------------------------')
    return text
endfunction

" whether need to sync same file
if !exists('g:ZFDirDiffUI_syncSameFile')
    let g:ZFDirDiffUI_syncSameFile = 0
endif

" overwrite confirm
if !exists('g:ZFDirDiffConfirmSyncDir')
    let g:ZFDirDiffConfirmSyncDir = 1
endif
if !exists('g:ZFDirDiffConfirmSyncFile')
    let g:ZFDirDiffConfirmSyncFile = 1
endif
if !exists('g:ZFDirDiffConfirmCopyDir')
    let g:ZFDirDiffConfirmCopyDir = 1
endif
if !exists('g:ZFDirDiffConfirmCopyFile')
    let g:ZFDirDiffConfirmCopyFile = 0
endif
if !exists('g:ZFDirDiffConfirmRemoveDir')
    let g:ZFDirDiffConfirmRemoveDir = 1
endif
if !exists('g:ZFDirDiffConfirmRemoveFile')
    let g:ZFDirDiffConfirmRemoveFile = 1
endif

" keymaps
if !exists('g:ZFDirDiffKeymap_update')
    let g:ZFDirDiffKeymap_update = ['DD']
endif
if !exists('g:ZFDirDiffKeymap_open')
    let g:ZFDirDiffKeymap_open = ['<cr>', 'o']
endif
if !exists('g:ZFDirDiffKeymap_foldOpenAll')
    let g:ZFDirDiffKeymap_foldOpenAll = ['O']
endif
if !exists('g:ZFDirDiffKeymap_foldClose')
    let g:ZFDirDiffKeymap_foldClose = ['x']
endif
if !exists('g:ZFDirDiffKeymap_foldCloseAll')
    let g:ZFDirDiffKeymap_foldCloseAll = ['X']
endif
if !exists('g:ZFDirDiffKeymap_goParent')
    let g:ZFDirDiffKeymap_goParent = ['U']
endif
if !exists('g:ZFDirDiffKeymap_diffThisDir')
    let g:ZFDirDiffKeymap_diffThisDir = ['cd']
endif
if !exists('g:ZFDirDiffKeymap_diffParentDir')
    let g:ZFDirDiffKeymap_diffParentDir = ['u']
endif
if !exists('g:ZFDirDiffKeymap_markToDiff')
    let g:ZFDirDiffKeymap_markToDiff = ['DM']
endif
if !exists('g:ZFDirDiffKeymap_quit')
    let g:ZFDirDiffKeymap_quit = ['q']
endif
if !exists('g:ZFDirDiffKeymap_quitFileDiff')
    let g:ZFDirDiffKeymap_quitFileDiff = g:ZFDirDiffKeymap_quit
endif
if !exists('g:ZFDirDiffKeymap_nextDiff')
    let g:ZFDirDiffKeymap_nextDiff = [']c', 'DJ']
endif
if !exists('g:ZFDirDiffKeymap_prevDiff')
    let g:ZFDirDiffKeymap_prevDiff = ['[c', 'DK']
endif
if !exists('g:ZFDirDiffKeymap_syncToHere')
    let g:ZFDirDiffKeymap_syncToHere = ['do', 'DH']
endif
if !exists('g:ZFDirDiffKeymap_syncToThere')
    let g:ZFDirDiffKeymap_syncToThere = ['dp', 'DL']
endif
if !exists('g:ZFDirDiffKeymap_deleteFile')
    let g:ZFDirDiffKeymap_deleteFile = ['dd']
endif
if !exists('g:ZFDirDiffKeymap_getPath')
    let g:ZFDirDiffKeymap_getPath = ['p']
endif
if !exists('g:ZFDirDiffKeymap_getFullPath')
    let g:ZFDirDiffKeymap_getFullPath = ['P']
endif

" highlight
" {Title,Dir,Same,Diff,DirOnlyHere,DirOnlyThere,FileOnlyHere,FileOnlyThere,ConflictDir,ConflictFile}
highlight link ZFDirDiffHL_Title Title
highlight link ZFDirDiffHL_Dir Directory
highlight link ZFDirDiffHL_DirFolded Directory
highlight link ZFDirDiffHL_Same Folded
highlight link ZFDirDiffHL_Diff DiffText
highlight link ZFDirDiffHL_DirOnlyHere DiffAdd
highlight link ZFDirDiffHL_DirOnlyThere Normal
highlight link ZFDirDiffHL_FileOnlyHere DiffAdd
highlight link ZFDirDiffHL_FileOnlyThere Normal
highlight link ZFDirDiffHL_ConflictDir ErrorMsg
highlight link ZFDirDiffHL_ConflictFile WarningMsg
highlight link ZFDirDiffHL_MarkToDiff Cursor

" custom highlight function
if !exists('g:ZFDirDiffHLFunc_resetHL')
    let g:ZFDirDiffHLFunc_resetHL='ZF_DirDiffHL_resetHL_default'
endif
if !exists('g:ZFDirDiffHLFunc_addHL')
    let g:ZFDirDiffHLFunc_addHL='ZF_DirDiffHL_addHL_default'
endif

" ============================================================
command! -nargs=+ -complete=file ZFDirDiff :call ZF_DirDiff(<f-args>)

" ============================================================
function! ZF_DirDiff(fileLeft, fileRight)
    let diffResult = ZF_DirDiffCore(a:fileLeft, a:fileRight)
    if diffResult['exitCode'] == g:ZFDirDiff_exitCode_BothFile
        call s:diffByFile(a:fileLeft, a:fileRight)
    else
        call s:ZF_DirDiff_UI(a:fileLeft, a:fileRight, diffResult)
    endif
    echo diffResult['exitHint']
    return diffResult
endfunction

" optional params:
" * fileLeft, fileRight : when specified, use as new diff setting
" * folded : a dict whose key is relative path to diff,
"            indicates these items should be folded
function! ZF_DirDiffUpdate(...)
    if !exists('t:ZFDirDiff_dataUI')
        echo '[ZFDirDiff] no previous diff found'
        return
    endif

    let fileLeft = get(a:, 1, t:ZFDirDiff_fileLeftOrig)
    let fileRight = get(a:, 2, t:ZFDirDiff_fileRightOrig)
    let folded = get(a:, 3, {})
    let isLeft = b:ZFDirDiff_isLeft
    let cursorPos = getpos('.')
    if fileLeft == t:ZFDirDiff_fileLeftOrig && fileRight == t:ZFDirDiff_fileRightOrig
                \ && empty(folded)
        let folded = ZF_DirDiffGetFolded()
    endif

    let diffResult = ZF_DirDiffCore(fileLeft, fileRight)
    let t:ZFDirDiff_fileLeft = ZF_DirDiffPathFormat(fileLeft)
    let t:ZFDirDiff_fileRight = ZF_DirDiffPathFormat(fileRight)
    let t:ZFDirDiff_fileLeftOrig = substitute(substitute(fileLeft, '\\', '/', 'g'), '/\+$', '', 'g')
    let t:ZFDirDiff_fileRightOrig = substitute(substitute(fileRight, '\\', '/', 'g'), '/\+$', '', 'g')
    let t:ZFDirDiff_hasDiff = (diffResult['exitCode'] == g:ZFDirDiff_exitCode_HasDiff)
    let t:ZFDirDiff_data = diffResult['data']
    if diffResult['exitCode'] == g:ZFDirDiff_exitCode_BothFile
        call ZF_DirDiffQuit()
        call s:diffByFile(fileLeft, fileRight)
        return
    endif

    call s:setupDiffDataUI()
    for dataUI in t:ZFDirDiff_dataUI
        if get(folded, dataUI.data.path, 0)
            let dataUI.folded = 1
        endif
    endfor
    call s:ZF_DirDiff_redraw()

    if isLeft
        execute "normal! \<c-w>h"
    endif
    call setpos('.', cursorPos)
endfunction

function! ZF_DirDiffGetFolded()
    if !exists('t:ZFDirDiff_dataUI')
        return {}
    endif
    let folded = {}
    for dataUI in t:ZFDirDiff_dataUI
        if dataUI.folded
            let folded[dataUI.data.path] = 1
        endif
    endfor
    return folded
endfunction

function! ZF_DirDiffDataUIUnderCursor()
    return s:getDataUIUnderCursor()
endfunction

function! ZF_DirDiffOpen()
    let dataUI = s:getDataUIUnderCursor()
    if empty(dataUI)
        return
    endif
    if index(['T_DIR', 'T_DIR_LEFT', 'T_DIR_RIGHT'], dataUI.data.type) >= 0
        let dataUI.folded = dataUI.folded ? 0 : 1
        call s:ZF_DirDiff_redraw()
        return
    endif
    if index(['T_CONFLICT_DIR_LEFT', 'T_CONFLICT_DIR_RIGHT'], dataUI.data.type) >= 0
        echo '[ZFDirDiff] can not be compared: ' . dataUI.data.path
        return
    endif

    let fileLeft = t:ZFDirDiff_fileLeftOrig . '/' . dataUI.data.path
    let fileRight = t:ZFDirDiff_fileRightOrig . '/' . dataUI.data.path

    call s:diffByFile(fileLeft, fileRight)
endfunction

function! ZF_DirDiffFoldOpenAll()
    let dataUI = s:getDataUIUnderCursor()
    if empty(dataUI) || index(['T_DIR', 'T_DIR_LEFT', 'T_DIR_RIGHT'], dataUI.data.type) < 0
        return
    endif

    let dataUI.folded = 0
    let level = dataUI.data.level
    let i = dataUI.indexVisible + 1
    let iEnd = len(t:ZFDirDiff_dataUI)
    while i < iEnd
        let dataUI = t:ZFDirDiff_dataUI[i]
        if dataUI.data.level <= level
            break
        endif
        let dataUI.folded = 0
        let i += 1
    endwhile

    call s:ZF_DirDiff_redraw()
endfunction

function! ZF_DirDiffFoldClose()
    let dataUI = s:getDataUIUnderCursor()
    if empty(dataUI)
        return
    endif

    let level = dataUI.data.level
    let i = dataUI.indexVisible - 1
    while i >= 0
        let dataUI = t:ZFDirDiff_dataUIVisible[i]
        if dataUI.data.level < level
            let dataUI.folded = 1
            break
        endif
        let i -= 1
    endwhile

    call s:ZF_DirDiff_redraw()
    if i >= 0
        let cursor = getpos('.')
        let cursor[1] = i + b:ZFDirDiff_iLineOffset + 1
        call setpos('.', cursor)
    endif
endfunction

function! ZF_DirDiffFoldCloseAll()
    let isDirCheck = ['T_DIR', 'T_DIR_LEFT', 'T_DIR_RIGHT']
    for dataUI in t:ZFDirDiff_dataUI
        if index(isDirCheck, dataUI.data.type) >= 0
            let dataUI.folded = 1
        endif
    endfor
    call s:ZF_DirDiff_redraw()
    let cursor = getpos('.')
    let cursor[1] = b:ZFDirDiff_iLineOffset + 1
    call setpos('.', cursor)
endfunction

function! ZF_DirDiffGoParent()
    let fileLeft = fnamemodify(t:ZFDirDiff_fileLeftOrig, ':h')
    let fileRight = fnamemodify(t:ZFDirDiff_fileRightOrig, ':h')
    let name = fnamemodify(fileLeft, ':t')
    let folded = {}
    for item in keys(ZF_DirDiffGetFolded())
        let folded[name . '/' . item] = 1
    endfor
    call ZF_DirDiffUpdate(fileLeft, fileRight, folded)
endfunction

function! ZF_DirDiffDiffThisDir()
    let dataUI = s:getDataUIUnderCursor()
    if empty(dataUI)
        return
    endif
    if b:ZFDirDiff_isLeft
        let fileRight = t:ZFDirDiff_fileRightOrig
        let fileLeft = t:ZFDirDiff_fileLeftOrig . '/' . dataUI.data.path
        if index(['T_DIR', 'T_DIR_LEFT', 'T_CONFLICT_DIR_LEFT'], dataUI.data.type) < 0
            let fileLeft = fnamemodify(fileLeft, ':h')
        endif
    else
        let fileLeft = t:ZFDirDiff_fileLeftOrig
        let fileRight = t:ZFDirDiff_fileRightOrig . '/' . dataUI.data.path
        if index(['T_DIR', 'T_DIR_RIGHT', 'T_CONFLICT_DIR_RIGHT'], dataUI.data.type) < 0
            let fileRight = fnamemodify(fileRight, ':h')
        endif
    endif
    call ZF_DirDiffUpdate(fileLeft, fileRight)
endfunction

function! ZF_DirDiffDiffParentDir()
    let fileLeft = b:ZFDirDiff_isLeft ? fnamemodify(t:ZFDirDiff_fileLeftOrig, ':h') : t:ZFDirDiff_fileLeftOrig
    let fileRight = !b:ZFDirDiff_isLeft ? fnamemodify(t:ZFDirDiff_fileRightOrig, ':h') : t:ZFDirDiff_fileRightOrig
    call ZF_DirDiffUpdate(fileLeft, fileRight)
endfunction

function! ZF_DirDiffMarkToDiff()
    let indexVisible = getpos('.')[1] - b:ZFDirDiff_iLineOffset - 1
    if indexVisible < 0
                \ || indexVisible >= len(t:ZFDirDiff_dataUIVisible)
                \ || (b:ZFDirDiff_isLeft && index(['T_DIR_RIGHT', 'T_FILE_RIGHT'], t:ZFDirDiff_dataUIVisible[indexVisible].data.type) >= 0)
                \ || (!b:ZFDirDiff_isLeft && index(['T_DIR_LEFT', 'T_FILE_LEFT'], t:ZFDirDiff_dataUIVisible[indexVisible].data.type) >= 0)
        echo '[ZFDirDiff] no file under cursor'
        return
    endif

    if !exists('t:ZFDirDiff_markToDiff')
        let t:ZFDirDiff_markToDiff = {
                    \   'isLeft' : b:ZFDirDiff_isLeft,
                    \   'index' : t:ZFDirDiff_dataUIVisible[indexVisible].index,
                    \ }
        call s:ZF_DirDiff_redraw()
        echo '[ZFDirDiff] mark again to diff with: '
                    \ . (b:ZFDirDiff_isLeft ? '[LEFT]' : '[RIGHT]')
                    \ . '/' . t:ZFDirDiff_dataUIVisible[indexVisible].data.path
        return
    endif

    if t:ZFDirDiff_markToDiff.isLeft == b:ZFDirDiff_isLeft
                \ && t:ZFDirDiff_markToDiff.index == t:ZFDirDiff_dataUIVisible[indexVisible].index
        unlet t:ZFDirDiff_markToDiff
        call s:ZF_DirDiff_redraw()
        return
    endif

    let fileLeft = (t:ZFDirDiff_markToDiff.isLeft ? t:ZFDirDiff_fileLeftOrig : t:ZFDirDiff_fileRightOrig)
                \ . '/' . t:ZFDirDiff_dataUI[t:ZFDirDiff_markToDiff.index].data.path
    let fileRight = (b:ZFDirDiff_isLeft ? t:ZFDirDiff_fileLeftOrig : t:ZFDirDiff_fileRightOrig)
                \ . '/' . t:ZFDirDiff_dataUIVisible[indexVisible].data.path
    unlet t:ZFDirDiff_markToDiff
    call ZF_DirDiffUpdate(fileLeft, fileRight)
endfunction

function! ZF_DirDiffQuit()
    let Fn_resetHL=function(g:ZFDirDiffHLFunc_resetHL)
    let ownerTab = t:ZFDirDiff_ownerTab

    " note winnr('$') always equal to 1 for last window
    while winnr('$') > 1
        call Fn_resetHL()
        set nocursorbind
        set noscrollbind
        bd!
    endwhile
    " delete again to delete last window
    call Fn_resetHL()
    set nocursorbind
    set noscrollbind
    bd!

    execute 'normal! ' . ownerTab . 'gt'
endfunction

function! ZF_DirDiffQuitFileDiff()
    let ownerDiffTab = t:ZFDirDiff_ownerDiffTab

    execute "normal! \<c-w>k"
    execute "normal! \<c-w>h"
    call s:askWrite()

    execute "normal! \<c-w>k"
    execute "normal! \<c-w>l"
    call s:askWrite()

    let tabnr = tabpagenr('$')
    while exists('t:ZFDirDiff_ownerDiffTab') && tabnr == tabpagenr('$')
        bd!
    endwhile

    execute 'normal! ' . ownerDiffTab . 'gt'
    call ZF_DirDiffUpdate()
endfunction

function! ZF_DirDiffNextDiff()
    call s:jumpDiff('next')
endfunction
function! ZF_DirDiffPrevDiff()
    call s:jumpDiff('prev')
endfunction
function! s:jumpDiff(nextOrPrev)
    if a:nextOrPrev == 'next'
        let iOffset = 1
        let iEnd = len(t:ZFDirDiff_dataUIVisible)
    else
        let iOffset = -1
        let iEnd = -1
    endif

    let curPos = getpos('.')
    let iLine = curPos[1] - b:ZFDirDiff_iLineOffset - 1
    if iLine < 0
        let iLine = 0
    elseif iLine >= len(t:ZFDirDiff_dataUIVisible)
        let iLine = len(t:ZFDirDiff_dataUIVisible) - 1
    else
        let iLine += iOffset
    endif

    while iLine != iEnd
        let dataUI = t:ZFDirDiff_dataUIVisible[iLine]
        if dataUI.data.type != 'T_DIR' && dataUI.data.type != 'T_SAME'
            let curPos[1] = iLine + b:ZFDirDiff_iLineOffset + 1
            call setpos('.', curPos)
            normal! zz
            break
        endif
        let iLine += iOffset
    endwhile
endfunction

function! ZF_DirDiffFoldLevelUpdate(foldLevel)
    if a:foldLevel <= 0
        for dataUI in t:ZFDirDiff_dataUI
            let dataUI.folded = 0
        endfor
    else
        for dataUI in t:ZFDirDiff_dataUI
            let dataUI.folded = (dataUI.data.level >= a:foldLevel) ? 1 : 0
        endfor
    endif
    call s:setupDiffDataUIVisible()
endfunction

function! ZF_DirDiffSyncToHere()
    let dataUI = s:getDataUIUnderCursor()
    if empty(dataUI)
        return
    endif
    call ZF_DirDiffSync(t:ZFDirDiff_fileLeft, t:ZFDirDiff_fileRight, dataUI.data.path, dataUI.data, b:ZFDirDiff_isLeft ? 'r2l' : 'l2r', 0)
    call ZF_DirDiffUpdate()
endfunction
function! ZF_DirDiffSyncToThere()
    let dataUI = s:getDataUIUnderCursor()
    if empty(dataUI)
        return
    endif
    call ZF_DirDiffSync(t:ZFDirDiff_fileLeft, t:ZFDirDiff_fileRight, dataUI.data.path, dataUI.data, b:ZFDirDiff_isLeft ? 'l2r' : 'r2l', 0)
    call ZF_DirDiffUpdate()
endfunction

function! ZF_DirDiffDeleteFile()
    let dataUI = s:getDataUIUnderCursor()
    if empty(dataUI)
        return
    endif
    call ZF_DirDiffSync(t:ZFDirDiff_fileLeft, t:ZFDirDiff_fileRight, dataUI.data.path, dataUI.data, b:ZFDirDiff_isLeft ? 'dl' : 'dr', 0)
    call ZF_DirDiffUpdate()
endfunction

function! ZF_DirDiffGetPath()
    let dataUI = s:getDataUIUnderCursor()
    if empty(dataUI)
        return
    endif

    let path = fnamemodify(b:ZFDirDiff_isLeft ? t:ZFDirDiff_fileLeftOrig : t:ZFDirDiff_fileRightOrig, ':.') . '/' . dataUI.data.path
    let path = substitute(path, '\', '/', 'g')
    if has('clipboard')
        let @*=path
    else
        let @"=path
    endif

    echo '[ZFDirDiff] copied path: ' . path
endfunction
function! ZF_DirDiffGetFullPath()
    let dataUI = s:getDataUIUnderCursor()
    if empty(dataUI)
        return
    endif

    let path = (b:ZFDirDiff_isLeft ? t:ZFDirDiff_fileLeft : t:ZFDirDiff_fileRight) . '/' . dataUI.data.path
    if has('clipboard')
        let @*=path
    else
        let @"=path
    endif

    echo '[ZFDirDiff] copied full path: ' . path
endfunction

" ============================================================
function! s:diffByFile(fileLeft, fileRight)
    let ownerDiffTab = tabpagenr()

    execute 'tabedit ' . a:fileLeft
    diffthis
    call s:diffByFile_setup(ownerDiffTab)

    vsplit

    execute "normal! \<c-w>l"
    execute 'edit ' . a:fileRight
    diffthis
    call s:diffByFile_setup(ownerDiffTab)

    execute "normal! \<c-w>="
endfunction
function! s:diffByFile_setup(ownerDiffTab)
    let t:ZFDirDiff_ownerDiffTab = a:ownerDiffTab

    for k in g:ZFDirDiffKeymap_quitFileDiff
        execute 'nnoremap <buffer><silent> ' . k . ' :call ZF_DirDiffQuitFileDiff()<cr>'
    endfor

    doautocmd User ZFDirDiff_FileDiffEnter
endfunction

function! s:getDataUIUnderCursor()
    let iLine = getpos('.')[1] - b:ZFDirDiff_iLineOffset - 1
    if iLine >= 0 && iLine < len(t:ZFDirDiff_dataUIVisible)
        return t:ZFDirDiff_dataUIVisible[iLine]
    else
        return ''
    endif
endfunction

function! s:askWrite()
    if !&modified
        return
    endif
    let input = confirm("[ZFDirDiff] File " . expand("%:p") . " modified, save?", "&Yes\n&No", 1)
    if (input == 1)
        w!
    endif
endfunction

function! s:ZF_DirDiff_UI(fileLeft, fileRight, diffResult)
    let ownerTab = tabpagenr()

    tabnew

    let t:ZFDirDiff_ownerTab = ownerTab
    let t:ZFDirDiff_fileLeft = ZF_DirDiffPathFormat(a:fileLeft)
    let t:ZFDirDiff_fileRight = ZF_DirDiffPathFormat(a:fileRight)
    let t:ZFDirDiff_fileLeftOrig = substitute(substitute(a:fileLeft, '\\', '/', 'g'), '/\+$', '', 'g')
    let t:ZFDirDiff_fileRightOrig = substitute(substitute(a:fileRight, '\\', '/', 'g'), '/\+$', '', 'g')
    let t:ZFDirDiff_hasDiff = (a:diffResult['exitCode'] == g:ZFDirDiff_exitCode_HasDiff)
    let t:ZFDirDiff_data = a:diffResult['data']

    call s:setupDiffDataUI()
    call s:setupDiffDataUIVisible()

    vsplit
    call s:setupDiffUI(1)

    execute "normal! \<c-w>l"
    enew
    call s:setupDiffUI(0)

    execute 'normal! gg0'
    if b:ZFDirDiff_iLineOffset > 0
        execute 'normal! ' . b:ZFDirDiff_iLineOffset . 'j'
    endif
endfunction

function! s:ZF_DirDiff_redraw()
    if !exists('t:ZFDirDiff_ownerTab')
        return
    endif
    let oldWin = winnr()
    let oldState = winsaveview()

    call s:setupDiffDataUIVisible()

    execute "normal! \<c-w>h"
    call s:setupDiffUI(1)
    execute "normal! \<c-w>l"
    call s:setupDiffUI(0)

    execute oldWin . 'wincmd w'
    call winrestview(oldState)
    redraw
endfunction

function! s:setupDiffDataUI()
    let t:ZFDirDiff_dataUI = []
    call s:setupDiffDataUI_recursive(t:ZFDirDiff_data)
endfunction
function! s:setupDiffDataUI_recursive(data)
    let foldLevel = g:ZFDirDiffUI_foldlevel
    for data in a:data
        let dataUI = {
                    \   'index' : len(t:ZFDirDiff_dataUI),
                    \   'indexVisible' : -1,
                    \   'folded' : (foldLevel > 0 && data.level >= foldLevel) ? 1 : 0,
                    \   'data' : data,
                    \ }
        if g:ZFDirDiffUI_foldDirOnly && !dataUI.folded && (data.type == 'T_DIR_LEFT' || data.type == 'T_DIR_RIGHT')
            let dataUI.folded = 1
        endif
        call add(t:ZFDirDiff_dataUI, dataUI)
        call s:setupDiffDataUI_recursive(data.children)
    endfor
endfunction
function! s:setupDiffDataUIVisible()
    let t:ZFDirDiff_dataUIVisible = []
    let i = 0
    let iEnd = len(t:ZFDirDiff_dataUI)
    while i < iEnd
        let dataUI = t:ZFDirDiff_dataUI[i]
        let dataUI.indexVisible = len(t:ZFDirDiff_dataUIVisible)
        call add(t:ZFDirDiff_dataUIVisible, dataUI)
        if dataUI.folded
            let i += 1
            while i < iEnd && t:ZFDirDiff_dataUI[i].data.level > dataUI.data.level
                let t:ZFDirDiff_dataUI[i].indexVisible = -1
                let i += 1
            endwhile
        else
            let i += 1
        endif
    endwhile
endfunction

function! s:setupDiffUI(isLeft)
    let b:ZFDirDiff_isLeft = a:isLeft
    let b:ZFDirDiff_iLineOffset = 0

    if b:ZFDirDiff_isLeft
        execute 'setlocal filetype=' . g:ZFDirDiffUI_filetypeLeft
    else
        execute 'setlocal filetype=' . g:ZFDirDiffUI_filetypeRight
    endif

    setlocal modifiable
    silent! normal! gg"_dG
    let contents = []

    " header
    let Fn_headerText = function(g:ZFDirDiffUI_headerTextFunc)
    let headerText = Fn_headerText()
    let b:ZFDirDiff_iLineOffset = len(headerText)
    call extend(contents, headerText)

    " contents
    call s:setupDiffItemList(contents)

    " write
    call setline(1, contents)

    " other buffer setting
    call s:setupDiffBuffer()
endfunction

function! s:setupDiffItemList(contents)
    let indentText = ''
    for i in range(g:ZFDirDiffUI_tabstop)
        let indentText .= ' '
    endfor

    for dataUI in t:ZFDirDiff_dataUIVisible
        let data = dataUI.data
        let line = ''
        let visible = 0
                    \ || (b:ZFDirDiff_isLeft && (data.type == 'T_DIR_RIGHT' || data.type == 'T_FILE_RIGHT'))
                    \ || (!b:ZFDirDiff_isLeft && (data.type == 'T_DIR_LEFT' || data.type == 'T_FILE_LEFT'))
                    \ ? 0 : 1

        if visible
            for i in range(data.level + 1)
                let line .= indentText
            endfor
            let isDir = data.type == 'T_DIR'
                        \ || (b:ZFDirDiff_isLeft && (data.type == 'T_DIR_LEFT' || data.type == 'T_CONFLICT_DIR_LEFT'))
                        \ || (!b:ZFDirDiff_isLeft && (data.type == 'T_DIR_RIGHT' || data.type == 'T_CONFLICT_DIR_RIGHT'))

            if dataUI.folded
                let mark = g:ZFDirDiffUI_dirExpandable
            elseif isDir
                if (b:ZFDirDiff_isLeft && data.type == 'T_CONFLICT_DIR_LEFT')
                            \ || (!b:ZFDirDiff_isLeft && data.type == 'T_CONFLICT_DIR_RIGHT')
                    let mark = g:ZFDirDiffUI_dirExpandable
                else
                    let mark = g:ZFDirDiffUI_dirCollapsible
                endif
            else
                let mark = ''
            endif
            if !empty(mark)
                let line = strpart(line, 0, len(line) - len(mark) - 1)
                let line .= mark . ' '
            endif

            let line .= data.name
            if isDir
                let line .= '/'
            endif
        endif
        let line = substitute(line, ' \+$', '', 'g')
        call add(a:contents, line)
    endfor

    call add(a:contents, '')
endfunction

function! s:setupDiffBuffer()
    call s:setupDiffBuffer_keymap()
    call s:setupDiffBuffer_statusline()
    call s:setupDiffBuffer_highlight()

    execute 'setlocal tabstop=' . g:ZFDirDiffUI_tabstop
    execute 'setlocal softtabstop=' . g:ZFDirDiffUI_tabstop
    setlocal buftype=nowrite
    setlocal bufhidden=hide
    setlocal nowrap
    setlocal nomodified
    setlocal nomodifiable
    set scrollbind
    set cursorbind

    doautocmd User ZFDirDiff_DirDiffEnter
    redraw
endfunction

function! s:setupDiffBuffer_keymap()
    for k in g:ZFDirDiffKeymap_update
        execute 'nnoremap <buffer><silent> ' . k . ' :call ZF_DirDiffUpdate()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_open
        execute 'nnoremap <buffer><silent> ' . k . ' :call ZF_DirDiffOpen()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_foldOpenAll
        execute 'nnoremap <buffer><silent> ' . k . ' :call ZF_DirDiffFoldOpenAll()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_foldClose
        execute 'nnoremap <buffer><silent> ' . k . ' :call ZF_DirDiffFoldClose()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_foldCloseAll
        execute 'nnoremap <buffer><silent> ' . k . ' :call ZF_DirDiffFoldCloseAll()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_goParent
        execute 'nnoremap <buffer><silent> ' . k . ' :call ZF_DirDiffGoParent()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_diffThisDir
        execute 'nnoremap <buffer><silent> ' . k . ' :call ZF_DirDiffDiffThisDir()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_diffParentDir
        execute 'nnoremap <buffer><silent> ' . k . ' :call ZF_DirDiffDiffParentDir()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_markToDiff
        execute 'nnoremap <buffer><silent> ' . k . ' :call ZF_DirDiffMarkToDiff()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_quit
        execute 'nnoremap <buffer><silent> ' . k . ' :call ZF_DirDiffQuit()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_nextDiff
        execute 'nnoremap <buffer><silent> ' . k . ' :call ZF_DirDiffNextDiff()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_prevDiff
        execute 'nnoremap <buffer><silent> ' . k . ' :call ZF_DirDiffPrevDiff()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_syncToHere
        execute 'nnoremap <buffer><silent> ' . k . ' :call ZF_DirDiffSyncToHere()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_syncToThere
        execute 'nnoremap <buffer><silent> ' . k . ' :call ZF_DirDiffSyncToThere()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_deleteFile
        execute 'nnoremap <buffer><silent> ' . k . ' :call ZF_DirDiffDeleteFile()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_getPath
        execute 'nnoremap <buffer><silent> ' . k . ' :call ZF_DirDiffGetPath()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_getFullPath
        execute 'nnoremap <buffer><silent> ' . k . ' :call ZF_DirDiffGetFullPath()<cr>'
    endfor
endfunction

function! s:setupDiffBuffer_statusline()
    if b:ZFDirDiff_isLeft
        let hint = 'LEFT'
        let path = t:ZFDirDiff_fileLeftOrig
    else
        let hint = 'RIGHT'
        let path = t:ZFDirDiff_fileRightOrig
    endif
    let path = substitute(path, '%', '%%', 'g')
    let &l:statusline = '[' . hint . ']: ' . path . '%=%k %3p%%'
endfunction

function! s:setupDiffBuffer_highlight()
    let Fn_resetHL=function(g:ZFDirDiffHLFunc_resetHL)
    let Fn_addHL=function(g:ZFDirDiffHLFunc_addHL)

    call Fn_resetHL()

    if len(t:ZFDirDiff_dataUIVisible) > get(g:, 'ZFDirDiffHLMaxLine', 200)
        return
    endif

    for i in range(1, b:ZFDirDiff_iLineOffset)
        call Fn_addHL('ZFDirDiffHL_Title', i)
    endfor

    for indexVisible in range(len(t:ZFDirDiff_dataUIVisible))
        let dataUI = t:ZFDirDiff_dataUIVisible[indexVisible]
        let data = dataUI.data
        let line = b:ZFDirDiff_iLineOffset + indexVisible + 1

        if exists('t:ZFDirDiff_markToDiff')
                    \ && b:ZFDirDiff_isLeft == t:ZFDirDiff_markToDiff.isLeft
                    \ && t:ZFDirDiff_dataUIVisible[indexVisible].index == t:ZFDirDiff_markToDiff.index
            call Fn_addHL('ZFDirDiffHL_MarkToDiff', line)
            continue
        endif

        if 0
        elseif data.type == 'T_DIR'
            if dataUI.folded
                call Fn_addHL('ZFDirDiffHL_DirFolded', line)
            else
                call Fn_addHL('ZFDirDiffHL_Dir', line)
            endif
        elseif data.type == 'T_SAME'
            call Fn_addHL('ZFDirDiffHL_Same', line)
        elseif data.type == 'T_DIFF'
            call Fn_addHL('ZFDirDiffHL_Diff', line)
        elseif data.type == 'T_DIR_LEFT'
            if b:ZFDirDiff_isLeft
                call Fn_addHL('ZFDirDiffHL_DirOnlyHere', line)
            else
                call Fn_addHL('ZFDirDiffHL_DirOnlyThere', line)
            endif
        elseif data.type == 'T_DIR_RIGHT'
            if !b:ZFDirDiff_isLeft
                call Fn_addHL('ZFDirDiffHL_DirOnlyHere', line)
            else
                call Fn_addHL('ZFDirDiffHL_DirOnlyThere', line)
            endif
        elseif data.type == 'T_FILE_LEFT'
            if b:ZFDirDiff_isLeft
                call Fn_addHL('ZFDirDiffHL_FileOnlyHere', line)
            else
                call Fn_addHL('ZFDirDiffHL_FileOnlyThere', line)
            endif
        elseif data.type == 'T_FILE_RIGHT'
            if !b:ZFDirDiff_isLeft
                call Fn_addHL('ZFDirDiffHL_FileOnlyHere', line)
            else
                call Fn_addHL('ZFDirDiffHL_FileOnlyThere', line)
            endif
        elseif data.type == 'T_CONFLICT_DIR_LEFT'
            if b:ZFDirDiff_isLeft
                call Fn_addHL('ZFDirDiffHL_ConflictDir', line)
            else
                call Fn_addHL('ZFDirDiffHL_ConflictFile', line)
            endif
        elseif data.type == 'T_CONFLICT_DIR_RIGHT'
            if !b:ZFDirDiff_isLeft
                call Fn_addHL('ZFDirDiffHL_ConflictDir', line)
            else
                call Fn_addHL('ZFDirDiffHL_ConflictFile', line)
            endif
        endif
    endfor
endfunction

