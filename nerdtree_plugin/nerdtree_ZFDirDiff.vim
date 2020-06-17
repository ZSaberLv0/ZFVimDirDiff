
if !get(g:, 'ZFDirDiff_nerdtreeMenu_enable', 1)
    finish
endif

call NERDTreeAddMenuItem({
            \   'text': get(g:, 'ZFDirDiff_nerdtreeMenu_text', '(z) mark to diff'),
            \   'shortcut': get(g:, 'ZFDirDiff_nerdtreeMenu_key', 'z'),
            \   'callback': 'NERDTreeMarkToDiff',
            \ })

let s:markToDiff = ''
function! NERDTreeMarkToDiff()
    let path = g:NERDTreeFileNode.GetSelected().path.str()
    if empty(s:markToDiff)
        let s:markToDiff = path
        redraw!
        echo '[ZFDirDiff] ready to diff: [LEFT]: ' . path
        return
    endif

    let left = s:markToDiff
    let s:markToDiff = ''
    if left == path
        redraw!
        echo '[ZFDirDiff] canceled'
        return
    endif
    if get(g:, 'ZFDirDiff_nerdtreeMenu_addHistory', 1)
        call histadd(':', "call ZF_DirDiff('" . left . "', '" . path . "')")
    endif
    call ZF_DirDiff(left, path)
endfunction

