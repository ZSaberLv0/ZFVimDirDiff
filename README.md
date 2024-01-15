
# Intro

vim plugin to diff two directories like BeyondCompare by using `diff`

inspired by [will133/vim-dirdiff](https://github.com/will133/vim-dirdiff)

* why another directory diff plugin?

    * fully async and queued, works well with tons of files, even for vim 7.3!
        (by [ZFVimJob](https://github.com/ZSaberLv0/ZFVimJob))
    * works well on Windows without `sh` or `diff` env
    * format the diff result as vertical split file tree view,
        which should be more human-readable
    * more friendly file sync operation using the same mappings as builtin `vimdiff`
    * automatically backup before destructive actions
        (by [ZFVimBackup](https://github.com/ZSaberLv0/ZFVimBackup))
    * better file or directory exclude logic
        (by [ZFVimIgnore](https://github.com/ZSaberLv0/ZFVimIgnore))

![](https://raw.githubusercontent.com/ZSaberLv0/ZFVimDirDiff/master/preview.png)

if you like my work, [check here](https://github.com/ZSaberLv0?utf8=%E2%9C%93&tab=repositories&q=ZFVim) for a list of my vim plugins,
or [buy me a coffee](https://github.com/ZSaberLv0/ZSaberLv0)


# How to use

1. requirement

    * vim 8.0 or neovim : recommend, fully async
    * vim 7.3 or above : all features work as expected, with some lag due to lack of `job`

1. install by [vim-plug](https://github.com/junegunn/vim-plug) or any other plugin manager:

    ```
    Plug 'ZSaberLv0/ZFVimDirDiff'
    Plug 'ZSaberLv0/ZFVimJob' " required
    Plug 'ZSaberLv0/ZFVimIgnore' " optional, but recommended for auto ignore setup
    Plug 'ZSaberLv0/ZFVimBackup' " optional, but recommended for auto backup
    ```

1. use `:ZFDirDiff` command to start diff

    ```
    :ZFDirDiff pathA pathB
    ```

    if path contains spaces:

    ```
    :ZFDirDiff path\ A path\ B
    :call ZFDirDiff("path A", "path B")
    ```

1. use `:ZFDirDiffMark` to mark two directories to start diff

    Open a file and `:ZFDirDiffMark` and the containing directory will be stored as
    a diff candidate. Then repeat with another file and you'll be asked to
    diff the two.

    ```
    :edit pathA/file.vim
    :ZFDirDiffMark
    :edit pathB/file.vim
    :ZFDirDiffMark
    ```

    Or integrate with your file manager. For vim-dirvish, add
    ~/.vim/ftplugin/dirvish.vim:

        nnoremap <buffer> X :<C-u>ZFDirDiffMark <C-r><C-l><CR>

    Or for netrw, add ~/.vim/ftplugin/netrw.vim:

        nnoremap <buffer> X :<C-u>ZFDirDiffMark <C-r>=b:netrw_curdir<CR>/<C-r><C-l><CR>

    Then X on two directories.

1. you can also start diff from [scrooloose/nerdtree](https://github.com/scrooloose/nerdtree):
    inside nerdtree window, press `m` to popup menu,
    press `z` to choose `mark to diff`,
    and mark another node again to start diff

1. you may also use it as command line diff tool

    ```
    vim -c 'call ZFDirDiff("path A", "path B")'
    sh ZFDirDiff.sh "path A" "path B"
    ```

1. within the diff window:

    * use `DD` to update the diff result under cursor
    * use `o` or `<cr>` to diff current file, or fold/unfold current dir
    * use `O` to unfold all contents under current dir,
        `x` to fold to parent, `X` to fold to root
    * use `cd` to make current dir as diff root dir,
        `u` to go up for current side,
        and `U` to go up for both side
    * use `DM` to mark current file,
        and `DM` again on another file to diff these two files
    * use `]c` or `DJ` to move to next diff, `[c` or `DK` to prev diff,
        use `Dj` / `Dk` to move to next / prev diff file
    * use `do` or `DH` to sync from another side to current side,
        `dp` or `DL` to sync from current side to another side
    * use `a` to add new file or dir
    * use `dd` to delete node under cursor
    * use `DN` to mark mutiple files,
        when done, use `do/DH/dp/DL/dd` to sync or delete marked files
    * use `p` to copy the node's path, and `P` for the node's full path
    * use `q` to exit diff
    * you may also want to use [ZSaberLv0/ZFVimIndentMove](https://github.com/ZSaberLv0/ZFVimIndentMove)
        or [easymotion/vim-easymotion](https://github.com/easymotion/vim-easymotion)
        to quickly move between file tree node

1. within the file diff window:

    * it's vim's builtin diff, see `:h diff` for more info
    * use `q` to quick file diff and back to owner diff window


# Configs

this plugin should work well without any extra config

for experienced user, here's some configs you may interest


## Diff logic

* `let g:ZFDirDiff_autoBackup = 1` : whether perform auto backup, see https://github.com/ZSaberLv0/ZFVimBackup
* `let g:ZFDirDiff_ignoreEmptyDir = 1` : whether ignore empty dir
* `let g:ZFDirDiff_ignoreSpace = 0` : whether ignore empty lines and spaces (not supported for python backend)
* `let g:ZFIgnoreOption_ZFDirDiff = {...}` : ignore options, see https://github.com/ZSaberLv0/ZFVimIgnore

    ```
    let g:ZFIgnoreOption_ZFDirDiff = {
                \   'bin' : 0,
                \   'media' : 0,
                \   'ZFDirDiff' : 1,
                \ }
    ```


## Keymap (inside diff window)

* `let g:ZFDirDiffKeymap_update = ['DU']` : update entire diff window
* `let g:ZFDirDiffKeymap_updateParent = ['DD']` : update diff under cursor
* `let g:ZFDirDiffKeymap_open = ['<cr>', 'o']` : toggle dir open or open file diff
* `let g:ZFDirDiffKeymap_foldOpenAll = []` : open all node under cursor, including same files
* `let g:ZFDirDiffKeymap_foldOpenAllDiff = ['O']` : open all diff node under cursor
* `let g:ZFDirDiffKeymap_foldClose = ['x']` : close node
* `let g:ZFDirDiffKeymap_foldCloseAll = ['X']` : close all node
* `let g:ZFDirDiffKeymap_goParent = ['U']` : make both left and right diff window go to parent dir
* `let g:ZFDirDiffKeymap_diffThisDir = ['cd']` : change current side's root to node under cursor
* `let g:ZFDirDiffKeymap_diffParentDir = ['u']` : change current side's root to parent
* `let g:ZFDirDiffKeymap_markToDiff = ['DM']` : mark node under cursor, mark again to diff with two marked node
* `let g:ZFDirDiffKeymap_markToSync = ['DN']` : mark one or more nodes, to sync mutiple nodes at once
* `let g:ZFDirDiffKeymap_quit = ['q']` : quit diff
* `let g:ZFDirDiffKeymap_diffNext = [']c', 'DJ']` : jump to next visible diff
* `let g:ZFDirDiffKeymap_diffPrev = ['[c', 'DK']` : jump to prev visible diff
* `let g:ZFDirDiffKeymap_diffNextFile = ['Dj']` : jump to next diff file, auto open closed dir
* `let g:ZFDirDiffKeymap_diffPrevFile = ['Dk']` : jump to prev diff file, auto open closed dir
* `let g:ZFDirDiffKeymap_syncToHere = ['do', 'DH']` : sync nodes from there to here
* `let g:ZFDirDiffKeymap_syncToThere = ['dp', 'DL']` : sync nodes from here to there
* `let g:ZFDirDiffKeymap_add = ['a']` : add new node, end with `/` to add dir
* `let g:ZFDirDiffKeymap_delete = ['dd']` : delete selected nodes
* `let g:ZFDirDiffKeymap_getPath = ['p']` : get relative path of node under cursor
* `let g:ZFDirDiffKeymap_getFullPath = ['P']` : get absolute path of node under cursor


## Keymap (inside file diff window)

* `let g:ZFDirDiffKeymap_quitFileDiff = ['q']` : quit file diff, and go back to its owner diff window


## UI spec

* `let g:ZFDirDiffUIChar_dir_prefix_closed = '+ '`
* `let g:ZFDirDiffUIChar_dir_prefix_opened = '~ '`
* `let g:ZFDirDiffUIChar_dir_postfix = '/'`
* `let g:ZFDirDiffUIChar_file_prefix = '  '`
* `let g:ZFDirDiffUIChar_file_postfix = ''`
* `let g:ZFDirDiffUI_tabstop = 2`
* `let g:ZFDirDiffUI_autoOpenSingleChildDir = 1`
* `let g:ZFDirDiffUI_showSameDir = 1`
* `let g:ZFDirDiffUI_showSameFile = 1`


### Highlight

```
highlight default link ZFDirDiffHL_Header Title
highlight default link ZFDirDiffHL_Tail Title
highlight default link ZFDirDiffHL_DirChecking SpecialKey
highlight default link ZFDirDiffHL_DirSame Folded
highlight default link ZFDirDiffHL_DirDiff DiffAdd
highlight default link ZFDirDiffHL_FileChecking SpecialKey
highlight default link ZFDirDiffHL_FileSame Folded
highlight default link ZFDirDiffHL_FileDiff DiffText
highlight default link ZFDirDiffHL_DirOnlyHere DiffAdd
highlight default link ZFDirDiffHL_FileOnlyHere DiffAdd
highlight default link ZFDirDiffHL_ConflictDirHere ErrorMsg
highlight default link ZFDirDiffHL_ConflictDirThere WarningMsg
highlight default link ZFDirDiffHL_MarkToDiff Cursor
highlight default link ZFDirDiffHL_MarkToSync Cursor
```


# FAQ

* Q: screen keeps blink when diff updating in background

    A: unfortunately, I have no idea for how to solve this issue,
        mainly because of `matchadd()` must inside proper window,
        causing frequent window switching

