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

" autocmd
augroup ZF_DirDiff_augroup
    autocmd!
    autocmd User ZFDirDiff_BufferEnter silent
    autocmd User ZFDirDiff_FileEnter silent
augroup END

" function name to get the header text
"     YourFunc(isLeft, fileLeft, fileRight)
" return a list of string
if !exists('g:ZFDirDiffUI_headerTextFunc')
    let g:ZFDirDiffUI_headerTextFunc = 'ZF_DirDiff_headerText'
endif
function! ZF_DirDiff_headerText()
    let text = []
    if b:ZFDirDiff_isLeft
        call add(text, '[LEFT]: ' . ZF_DirDiffPathFormat(b:ZFDirDiff_fileLeft, ':~') . '/')
        call add(text, '[LEFT]: ' . ZF_DirDiffPathFormat(b:ZFDirDiff_fileLeft, ':.') . '/')
    else
        call add(text, '[RIGHT]: ' . ZF_DirDiffPathFormat(b:ZFDirDiff_fileRight, ':~') . '/')
        call add(text, '[RIGHT]: ' . ZF_DirDiffPathFormat(b:ZFDirDiff_fileRight, ':.') . '/')
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
if !exists('g:ZFDirDiffConfirmSyncConflict')
    let g:ZFDirDiffConfirmSyncConflict = 1
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
if !exists('g:ZFDirDiffKeymap_goParent')
    let g:ZFDirDiffKeymap_goParent = ['U']
endif
if !exists('g:ZFDirDiffKeymap_diffThisDir')
    let g:ZFDirDiffKeymap_diffThisDir = ['cd']
endif
if !exists('g:ZFDirDiffKeymap_diffParentDir')
    let g:ZFDirDiffKeymap_diffParentDir = ['u']
endif
if !exists('g:ZFDirDiffKeymap_quit')
    let g:ZFDirDiffKeymap_quit = ['q', 'x', 'X']
endif
if !exists('g:ZFDirDiffKeymap_quitDiff')
    let g:ZFDirDiffKeymap_quitDiff = ['q']
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
highlight link ZFDirDiffHL_Same Folded
highlight link ZFDirDiffHL_Diff DiffText
highlight link ZFDirDiffHL_DirOnlyHere DiffAdd
highlight link ZFDirDiffHL_DirOnlyThere Normal
highlight link ZFDirDiffHL_FileOnlyHere DiffAdd
highlight link ZFDirDiffHL_FileOnlyThere Normal
highlight link ZFDirDiffHL_ConflictDir ErrorMsg
highlight link ZFDirDiffHL_ConflictFile WarningMsg

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
    let ret = ZF_DirDiffCore(a:fileLeft, a:fileRight)
    if len(ret) == 1 && ret[0].name == ''
        call s:diffByFile(a:fileLeft, a:fileRight)
        return
    endif
    call s:ZF_DirDiff_UI(a:fileLeft, a:fileRight, ret)
    if empty(ret)
        redraw! | echo '[ZFDirDiff] no diff found'
    endif
endfunction

function! ZF_DirDiffUpdate()
    if !exists('b:ZFDirDiff_bufdata')
        redraw!
        echo '[ZFDirDiff] no previous diff found'
        return
    endif

    let fileLeft = b:ZFDirDiff_fileLeftOrig
    let fileRight = b:ZFDirDiff_fileRightOrig
    let isLeft = b:ZFDirDiff_isLeft
    let cursorPos = getpos('.')

    call ZF_DirDiffQuit()
    call ZF_DirDiff(fileLeft, fileRight)

    if isLeft
        execute "normal! \<c-w>h"
    endif
    call setpos('.', cursorPos)
endfunction

function! ZF_DirDiffOpen()
    let item = s:getItem()
    if empty(item)
        redraw
        return
    endif
    if item.type == 'T_DIR'
        let fileLeft = b:ZFDirDiff_fileLeftOrig . '/' . item.path
        let fileRight = b:ZFDirDiff_fileRightOrig . '/' . item.path
        call ZF_DirDiffQuit()
        call ZF_DirDiff(fileLeft, fileRight)
        return
    endif
    if item.type != 'T_SAME' && item.type != 'T_DIFF'
        redraw!
        echo '[ZFDirDiff] can not be compared: ' . item.path
        return
    endif

    let fileLeft = b:ZFDirDiff_fileLeftOrig . '/' . item.path
    let fileRight = b:ZFDirDiff_fileRightOrig . '/' . item.path

    call s:diffByFile(fileLeft, fileRight)
endfunction

function! ZF_DirDiffGoParent()
    let fileLeft = fnamemodify(b:ZFDirDiff_fileLeftOrig, ':h')
    let fileRight = fnamemodify(b:ZFDirDiff_fileRightOrig, ':h')
    call ZF_DirDiffQuit()
    call ZF_DirDiff(fileLeft, fileRight)
endfunction

function! ZF_DirDiffDiffThisDir()
    let item = s:getItem()
    if empty(item)
        redraw!
        return
    endif
    if b:ZFDirDiff_isLeft
        if index(['T_DIR', 'T_DIR_LEFT', 'T_CONFLICT_DIR_LEFT'], item.type) >= 0
            let itemPath = fnamemodify(b:ZFDirDiff_fileLeftOrig . '/' . item.path, ':p')
        else
            let itemPath = fnamemodify(b:ZFDirDiff_fileLeftOrig . '/' . item.path, ':p:h')
        endif
    else
        if index(['T_DIR', 'T_DIR_RIGHT', 'T_CONFLICT_DIR_RIGHT'], item.type) >= 0
            let itemPath = fnamemodify(b:ZFDirDiff_fileRightOrig . '/' . item.path, ':p')
        else
            let itemPath = fnamemodify(b:ZFDirDiff_fileRightOrig . '/' . item.path, ':p:h')
        endif
    endif

    let fileLeft = b:ZFDirDiff_isLeft ? itemPath : b:ZFDirDiff_fileLeftOrig
    let fileRight = !b:ZFDirDiff_isLeft ? itemPath : b:ZFDirDiff_fileRightOrig
    call ZF_DirDiffQuit()
    call ZF_DirDiff(fileLeft, fileRight)
endfunction

function! ZF_DirDiffDiffParentDir()
    let fileLeft = b:ZFDirDiff_isLeft ? fnamemodify(b:ZFDirDiff_fileLeftOrig, ':h') : b:ZFDirDiff_fileLeftOrig
    let fileRight = !b:ZFDirDiff_isLeft ? fnamemodify(b:ZFDirDiff_fileRightOrig, ':h') : b:ZFDirDiff_fileRightOrig
    call ZF_DirDiffQuit()
    call ZF_DirDiff(fileLeft, fileRight)
endfunction

function! ZF_DirDiffQuit()
    let Fn_resetHL=function(g:ZFDirDiffHLFunc_resetHL)
    let ownerTab = b:ZFDirDiff_ownerTab

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

function! ZF_DirDiffQuitDiff()
    let ownerDiffTab = b:ZFDirDiff_ownerDiffTab

    execute "normal! \<c-w>k"
    execute "normal! \<c-w>h"
    call s:askWrite()

    execute "normal! \<c-w>k"
    execute "normal! \<c-w>l"
    call s:askWrite()

    let tabnr = tabpagenr('$')
    while exists('b:ZFDirDiff_ownerDiffTab') && tabnr == tabpagenr('$')
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
    redraw

    if a:nextOrPrev == 'next'
        let iOffset = 1
        let iEnd = len(b:ZFDirDiff_bufdata)
    else
        let iOffset = -1
        let iEnd = -1
    endif

    let curPos = getpos('.')
    let iLine = curPos[1] - b:ZFDirDiff_iLineOffset - 1
    if iLine < 0
        let iLine = 0
    elseif iLine >= len(b:ZFDirDiff_bufdata)
        let iLine = len(b:ZFDirDiff_bufdata) - 1
    else
        let iLine += iOffset
    endif

    while iLine != iEnd
        let data = b:ZFDirDiff_bufdata[iLine]
        if data.type != 'T_DIR' && data.type != 'T_SAME'
            let curPos[1] = iLine + b:ZFDirDiff_iLineOffset + 1
            call setpos('.', curPos)
            normal! zz
            return
        endif
        let iLine += iOffset
    endwhile
endfunction

function! ZF_DirDiffSyncToHere()
    let item = s:getItem()
    if empty(item)
        redraw
        return
    endif
    call ZF_DirDiffSync(b:ZFDirDiff_fileLeft, b:ZFDirDiff_fileRight, item.path, item.data, b:ZFDirDiff_isLeft ? 'r2l' : 'l2r', 0)
    call ZF_DirDiffUpdate()
endfunction
function! ZF_DirDiffSyncToThere()
    let item = s:getItem()
    if empty(item)
        redraw
        return
    endif
    call ZF_DirDiffSync(b:ZFDirDiff_fileLeft, b:ZFDirDiff_fileRight, item.path, item.data, b:ZFDirDiff_isLeft ? 'l2r' : 'r2l', 0)
    call ZF_DirDiffUpdate()
endfunction

function! ZF_DirDiffDeleteFile()
    let item = s:getItem()
    if empty(item)
        redraw
        return
    endif
    call ZF_DirDiffSync(b:ZFDirDiff_fileLeft, b:ZFDirDiff_fileRight, item.path, item.data, b:ZFDirDiff_isLeft ? 'dl' : 'dr', 0)
    call ZF_DirDiffUpdate()
endfunction

function! ZF_DirDiffGetPath()
    let item = s:getItem()
    if empty(item)
        redraw
        return
    endif

    let path = fnamemodify(b:ZFDirDiff_isLeft ? b:ZFDirDiff_fileLeftOrig : b:ZFDirDiff_fileRightOrig, ':.') . item.path
    if has('clipboard')
        let @*=path
    else
        let @"=path
    endif

    redraw
    echo '[ZFDirDiff] copied path: ' . path
endfunction
function! ZF_DirDiffGetFullPath()
    let item = s:getItem()
    if empty(item)
        redraw
        return
    endif

    let path = (b:ZFDirDiff_isLeft ? b:ZFDirDiff_fileLeft : b:ZFDirDiff_fileRight) . item.path
    if has('clipboard')
        let @*=path
    else
        let @"=path
    endif

    redraw
    echo '[ZFDirDiff] copied full path: ' . path
endfunction

" ============================================================
function! s:diffByFile(fileLeft, fileRight)
    let ownerDiffTab = tabpagenr()

    execute 'tabedit ' . a:fileLeft
    diffthis
    call s:setupFileDiff(ownerDiffTab)

    vsplit

    execute "normal! \<c-w>l"
    execute 'edit ' . a:fileRight
    diffthis
    call s:setupFileDiff(ownerDiffTab)

    execute "normal! \<c-w>="
endfunction
function! s:setupFileDiff(ownerDiffTab)
    let b:ZFDirDiff_ownerDiffTab = a:ownerDiffTab

    for k in g:ZFDirDiffKeymap_quitDiff
        execute 'nnoremap <buffer> ' . k . ' :call ZF_DirDiffQuitDiff()<cr>'
    endfor

    doautocmd User ZFDirDiff_BufferEnter
endfunction

function! s:getItem()
    let iLine = getpos('.')[1] - b:ZFDirDiff_iLineOffset - 1
    if iLine >= 0 && iLine < len(b:ZFDirDiff_bufdata)
        return b:ZFDirDiff_bufdata[iLine]
    else
        return ''
    endif
endfunction

function! s:askWrite()
    if !&modified
        return
    endif
    redraw!
    let input = confirm("[ZFDirDiff] File " . expand("%:p") . " modified, save?", "&Yes\n&No", 1)
    if (input == 1)
        w!
    endif
endfunction

function! s:ZF_DirDiff_UI(fileLeft, fileRight, data)
    let ownerTab = tabpagenr()

    tabnew

    vsplit
    call s:setupDiffUI(ownerTab, a:fileLeft, a:fileRight, a:data, 1)

    execute "normal! \<c-w>l"
    enew
    call s:setupDiffUI(ownerTab, a:fileLeft, a:fileRight, a:data, 0)

    execute "normal! gg0"
endfunction

function! s:setupDiffUI(ownerTab, fileLeft, fileRight, data, isLeft)
    " [
    "   {
    "     'level' : 'indent level',
    "     'path' : 'relative path to fileLeft or fileRight',
    "     'name' : 'file or dir name',
    "     'type' : 'same as ZF_DirDiffCore type',
    "     'data' : { // original data of this node
    "       'name' : '',
    "       'type' : '',
    "       'children' : [...],
    "     },
    "   },
    "   ...
    " ]
    let b:ZFDirDiff_ownerTab = a:ownerTab
    let b:ZFDirDiff_bufdata = []
    let b:ZFDirDiff_fileLeft = ZF_DirDiffPathFormat(a:fileLeft)
    let b:ZFDirDiff_fileRight = ZF_DirDiffPathFormat(a:fileRight)
    let b:ZFDirDiff_fileLeftOrig = substitute(substitute(a:fileLeft, '\\', '/', 'g'), '/\+$', '', 'g')
    let b:ZFDirDiff_fileRightOrig = substitute(substitute(a:fileRight, '\\', '/', 'g'), '/\+$', '', 'g')
    let b:ZFDirDiff_isLeft = a:isLeft
    let b:ZFDirDiff_iLineOffset = 0

    if a:isLeft
        execute 'setlocal filetype=' . g:ZFDirDiffUI_filetypeLeft
    else
        execute 'setlocal filetype=' . g:ZFDirDiffUI_filetypeRight
    endif

    setlocal modifiable
    normal! gg"_dG

    " header
    let Fn_headerText = function(g:ZFDirDiffUI_headerTextFunc)
    let headerText = Fn_headerText()
    let b:ZFDirDiff_iLineOffset = len(headerText)
    for i in range(b:ZFDirDiff_iLineOffset)
        call setline(i + 1, headerText[i])
    endfor

    " contents
    let indentText = ''
    for i in range(g:ZFDirDiffUI_tabstop)
        let indentText .= ' '
    endfor
    call s:setupDiffItem(a:data, '', indentText, 1, b:ZFDirDiff_iLineOffset + 1, a:isLeft, 0)
    call setline(b:ZFDirDiff_iLineOffset + len(b:ZFDirDiff_bufdata) + 1, '')
    normal! gg0
    call s:setupDiffBuffer()
endfunction

function! s:setupDiffItem(data, parent, indentText, indent, iLine, isLeft, hiddenFlag)
    let iLine = a:iLine
    let incLine = 0
    if len(b:ZFDirDiff_bufdata) <= get(g:, 'ZFDirDiffHLMaxLine', 200)
        let markMap = get(g:, 'ZFDirDiffMarkMap', {
                    \   'T_DIR'                : ['', ''],
                    \   'T_SAME'               : ['', ''],
                    \   'T_DIFF'               : ['', ''],
                    \   'T_DIR_LEFT'           : ['', ''],
                    \   'T_DIR_RIGHT'          : ['', ''],
                    \   'T_FILE_LEFT'          : ['', ''],
                    \   'T_FILE_RIGHT'         : ['', ''],
                    \   'T_CONFLICT_DIR_LEFT'  : ['', ''],
                    \   'T_CONFLICT_DIR_RIGHT' : ['', ''],
                    \ })
    else
        let markMap = get(g:, 'ZFDirDiffMarkMap', {
                    \   'T_DIR'                : ['    ', '    '],
                    \   'T_SAME'               : ['    ', '    '],
                    \   'T_DIFF'               : ['[F] ', '[F] '],
                    \   'T_DIR_LEFT'           : ['[D] ', '    '],
                    \   'T_DIR_RIGHT'          : ['    ', '[D] '],
                    \   'T_FILE_LEFT'          : ['[F] ', '    '],
                    \   'T_FILE_RIGHT'         : ['    ', '[F] '],
                    \   'T_CONFLICT_DIR_LEFT'  : ['[D] ', '[F] '],
                    \   'T_CONFLICT_DIR_RIGHT' : ['[F] ', '[D] '],
                    \ })
    endif
    for item in a:data
        call add(b:ZFDirDiff_bufdata, {
                    \   'level' : a:indent,
                    \   'path' : a:parent . '/' . item.name,
                    \   'name' : item.name,
                    \   'type' : item.type,
                    \   'data' : item,
                    \ })

        let hiddenFlag = a:hiddenFlag
        if !hiddenFlag
            let hiddenFlag = 0
                        \ || (a:isLeft && (item.type == 'T_DIR_RIGHT' || item.type == 'T_FILE_RIGHT'))
                        \ || (!a:isLeft && (item.type == 'T_DIR_LEFT' || item.type == 'T_FILE_LEFT'))
                        \ ? 1 : 0
        endif

        let line = markMap[item.type][a:isLeft ? 0 : 1]
        if !hiddenFlag
            for i in range(a:indent)
                let line .= a:indentText
            endfor
            let line .= item.name
            if item.type == 'T_DIR'
                        \ || (a:isLeft && (item.type == 'T_DIR_LEFT' || item.type == 'T_CONFLICT_DIR_LEFT'))
                        \ || (!a:isLeft && (item.type == 'T_DIR_RIGHT' || item.type == 'T_CONFLICT_DIR_RIGHT'))
                let line .= '/'
            endif
        endif
        let line = substitute(line, ' \+$', '', 'g')

        call setline(iLine, line)
        let iLine += 1
        let incLine += 1

        let childIncLine = s:setupDiffItem(item.children, a:parent . '/' . item.name, a:indentText, a:indent + 1, iLine, a:isLeft, hiddenFlag)
        let iLine += childIncLine
        let incLine += childIncLine
    endfor
    return incLine
endfunction

function! s:setupDiffBuffer()
    call s:setupDiffBuffer_keymap()
    call s:setupDiffBuffer_statusline()
    if len(b:ZFDirDiff_bufdata) <= get(g:, 'ZFDirDiffHLMaxLine', 200)
        call s:setupDiffBuffer_highlight()
    endif

    execute 'set tabstop=' . g:ZFDirDiffUI_tabstop
    setlocal buftype=nowrite
    setlocal bufhidden=hide
    setlocal nowrap
    setlocal nomodified
    setlocal nomodifiable
    set scrollbind
    set cursorbind

    doautocmd User ZFDirDiff_FileEnter
endfunction

function! s:setupDiffBuffer_keymap()
    for k in g:ZFDirDiffKeymap_update
        execute 'nnoremap <buffer> ' . k . ' :call ZF_DirDiffUpdate()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_open
        execute 'nnoremap <buffer> ' . k . ' :call ZF_DirDiffOpen()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_goParent
        execute 'nnoremap <buffer> ' . k . ' :call ZF_DirDiffGoParent()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_diffThisDir
        execute 'nnoremap <buffer> ' . k . ' :call ZF_DirDiffDiffThisDir()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_diffParentDir
        execute 'nnoremap <buffer> ' . k . ' :call ZF_DirDiffDiffParentDir()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_quit
        execute 'nnoremap <buffer> ' . k . ' :call ZF_DirDiffQuit()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_nextDiff
        execute 'nnoremap <buffer> ' . k . ' :call ZF_DirDiffNextDiff()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_prevDiff
        execute 'nnoremap <buffer> ' . k . ' :call ZF_DirDiffPrevDiff()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_syncToHere
        execute 'nnoremap <buffer> ' . k . ' :call ZF_DirDiffSyncToHere()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_syncToThere
        execute 'nnoremap <buffer> ' . k . ' :call ZF_DirDiffSyncToThere()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_deleteFile
        execute 'nnoremap <buffer> ' . k . ' :call ZF_DirDiffDeleteFile()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_getPath
        execute 'nnoremap <buffer> ' . k . ' :call ZF_DirDiffGetPath()<cr>'
    endfor
    for k in g:ZFDirDiffKeymap_getFullPath
        execute 'nnoremap <buffer> ' . k . ' :call ZF_DirDiffGetFullPath()<cr>'
    endfor
endfunction

function! s:setupDiffBuffer_statusline()
    if b:ZFDirDiff_isLeft
        let hint = 'LEFT'
        let path = b:ZFDirDiff_fileLeftOrig
    else
        let hint = 'RIGHT'
        let path = b:ZFDirDiff_fileRightOrig
    endif
    let path = path . '/'
    let path = substitute(path, ' ', '\\ ', 'g')
    execute 'setlocal statusline=[' . hint . ']:\ ' . path
    setlocal statusline+=%=%k
    setlocal statusline+=\ %3p%%
endfunction

function! s:setupDiffBuffer_highlight()
    let Fn_resetHL=function(g:ZFDirDiffHLFunc_resetHL)
    let Fn_addHL=function(g:ZFDirDiffHLFunc_addHL)

    call Fn_resetHL()

    for i in range(1, b:ZFDirDiff_iLineOffset)
        call Fn_addHL('ZFDirDiffHL_Title', i)
    endfor

    let iLine = 1
    for item in b:ZFDirDiff_bufdata
        let line = b:ZFDirDiff_iLineOffset + iLine
        let iLine += 1

        if 0
        elseif item.type == 'T_DIR'
            call Fn_addHL('ZFDirDiffHL_Dir', line)
        elseif item.type == 'T_SAME'
            call Fn_addHL('ZFDirDiffHL_Same', line)
        elseif item.type == 'T_DIFF'
            call Fn_addHL('ZFDirDiffHL_Diff', line)
        elseif item.type == 'T_DIR_LEFT'
            if b:ZFDirDiff_isLeft
                call Fn_addHL('ZFDirDiffHL_DirOnlyHere', line)
            else
                call Fn_addHL('ZFDirDiffHL_DirOnlyThere', line)
            endif
        elseif item.type == 'T_DIR_RIGHT'
            if !b:ZFDirDiff_isLeft
                call Fn_addHL('ZFDirDiffHL_DirOnlyHere', line)
            else
                call Fn_addHL('ZFDirDiffHL_DirOnlyThere', line)
            endif
        elseif item.type == 'T_FILE_LEFT'
            if b:ZFDirDiff_isLeft
                call Fn_addHL('ZFDirDiffHL_FileOnlyHere', line)
            else
                call Fn_addHL('ZFDirDiffHL_FileOnlyThere', line)
            endif
        elseif item.type == 'T_FILE_RIGHT'
            if !b:ZFDirDiff_isLeft
                call Fn_addHL('ZFDirDiffHL_FileOnlyHere', line)
            else
                call Fn_addHL('ZFDirDiffHL_FileOnlyThere', line)
            endif
        elseif item.type == 'T_CONFLICT_DIR_LEFT'
            if b:ZFDirDiff_isLeft
                call Fn_addHL('ZFDirDiffHL_ConflictDir', line)
            else
                call Fn_addHL('ZFDirDiffHL_ConflictFile', line)
            endif
        elseif item.type == 'T_CONFLICT_DIR_RIGHT'
            if !b:ZFDirDiff_isLeft
                call Fn_addHL('ZFDirDiffHL_ConflictDir', line)
            else
                call Fn_addHL('ZFDirDiffHL_ConflictFile', line)
            endif
        endif
    endfor
endfunction

