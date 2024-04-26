
if !exists('g:ZFDirDiff_python')
    if 0
    elseif executable('py3')
        let g:ZFDirDiff_python = 'py3'
    elseif executable('python3')
        let g:ZFDirDiff_python = 'python3'
    elseif executable('py')
        let g:ZFDirDiff_python = 'py'
    elseif executable('python')
        let g:ZFDirDiff_python = 'python'
    else
        let g:ZFDirDiff_python = ''
    endif
endif

" ============================================================
if !exists('g:ZFDirDiffCmd_scriptPath')
    let g:ZFDirDiffCmd_scriptPath = expand('<sfile>:p:h:h') . '/misc'
endif

" return a jobOption that print a plain list of name or path of dir
if !exists('*ZFDirDiffCmd_listDir')
    if (has('win32') || has('win64')) && !has('unix')
        function! ZFDirDiffCmd_listDir(absPath)
            if ZFDirDiff_python_available()
                return ZFDirDiffCmd_listDir_python(a:absPath)
            endif
            return {
                        \   'jobCmd' : printf('"%s/listDir.bat" "%s"'
                        \       , CygpathFix_absPath(g:ZFDirDiffCmd_scriptPath)
                        \       , a:absPath
                        \   ),
                        \   'jobEncoding' : ZFJobImplGetWindowsEncoding(),
                        \ }
        endfunction
    else
        function! ZFDirDiffCmd_listDir(absPath)
            if ZFDirDiff_python_available()
                return ZFDirDiffCmd_listDir_python(a:absPath)
            endif
            return {
                        \   'jobCmd' : printf('sh "%s/listDir.sh" "%s"'
                        \       , CygpathFix_absPath(g:ZFDirDiffCmd_scriptPath)
                        \       , a:absPath
                        \   ),
                        \ }
        endfunction
    endif
endif

" return a jobOption that print a plain list of name or path of file
if !exists('*ZFDirDiffCmd_listFile')
    if (has('win32') || has('win64')) && !has('unix')
        function! ZFDirDiffCmd_listFile(absPath)
            if ZFDirDiff_python_available()
                return ZFDirDiffCmd_listFile_python(a:absPath)
            endif
            return {
                        \   'jobCmd' : printf('"%s/listFile.bat" "%s"'
                        \       , CygpathFix_absPath(g:ZFDirDiffCmd_scriptPath)
                        \       , a:absPath
                        \   ),
                        \   'jobEncoding' : ZFJobImplGetWindowsEncoding(),
                        \ }
        endfunction
    else
        function! ZFDirDiffCmd_listFile(absPath)
            if ZFDirDiff_python_available()
                return ZFDirDiffCmd_listFile_python(a:absPath)
            endif
            return {
                        \   'jobCmd' : printf('sh "%s/listFile.sh" "%s"'
                        \       , CygpathFix_absPath(g:ZFDirDiffCmd_scriptPath)
                        \       , a:absPath
                        \   ),
                        \ }
        endfunction
    endif
endif

" return a jobOption that diff two files and return proper exit code: 0: no diff, 1: has diff, 2: error
if !exists('*ZFDirDiffCmd_diff')
    if (has('win32') || has('win64')) && !has('unix')
        function! ZFDirDiffCmd_diff(absPathL, absPathR)
            if ZFDirDiff_python_available()
                return ZFDirDiffCmd_diff_python(a:absPathL, a:absPathR)
            endif
            return {
                        \   'jobCmd' : printf('"%s/diff.bat" "%s" "%s"'
                        \       , CygpathFix_absPath(g:ZFDirDiffCmd_scriptPath)
                        \       , a:absPathL
                        \       , a:absPathR
                        \   ),
                        \   'jobEncoding' : ZFJobImplGetWindowsEncoding(),
                        \   'jobEnv' : {
                        \     'ZFDIRDIFF_IGNORE_SPACE' : get(t:, 'ZFDirDiff_ignoreSpace', get(g:, 'ZFDirDiff_ignoreSpace', 0)),
                        \   },
                        \ }
        endfunction
    else
        function! ZFDirDiffCmd_diff(absPathL, absPathR)
            if ZFDirDiff_python_available()
                return ZFDirDiffCmd_diff_python(a:absPathL, a:absPathR)
            endif
            return {
                        \   'jobCmd' : printf('sh "%s/diff.sh" "%s" "%s"'
                        \       , CygpathFix_absPath(g:ZFDirDiffCmd_scriptPath)
                        \       , a:absPathL
                        \       , a:absPathR
                        \   ),
                        \   'jobEnv' : {
                        \     'ZFDIRDIFF_IGNORE_SPACE' : get(t:, 'ZFDirDiff_ignoreSpace', get(g:, 'ZFDirDiff_ignoreSpace', 0)),
                        \   },
                        \ }
        endfunction
    endif
endif

