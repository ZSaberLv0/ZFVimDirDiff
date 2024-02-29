
if !exists('g:ZFDirDiff_excludeFallback')
    let g:ZFDirDiff_excludeFallback = [
                \   '^\..*$',
                \   '^\~.*$',
                \   '^.*\~$',
                \ ]
endif

" ============================================================
function! ZFDirDiff_excludeCheck_fallback(taskData, diffNode)
    for pattern in g:ZFDirDiff_excludeFallback
        if match(a:diffNode['name'], pattern) >= 0
            return 1
        endif
    endfor
    return 0
endfunction

" ============================================================
if !exists('s:ZFIgnoreStateId')
    let s:ZFIgnoreStateId = 0
endif
augroup ZFDirDiff_excludeCheck_ZFIgnore_augroup
    autocmd!
    autocmd User ZFIgnoreOnUpdate let s:ZFIgnoreStateId += 1
augroup END

function! s:ZFIgnoreAction_dir(taskData, diffNode)
    for pattern in get(get(a:taskData, 'ZFIgnore_excludeState', {}), 'dir_patterns', [])
        if match(a:diffNode['name'], pattern) >= 0
            return 1
        endif
    endfor
endfunction
function! s:ZFIgnoreAction_file(taskData, diffNode)
    for pattern in get(get(a:taskData, 'ZFIgnore_excludeState', {}), 'file_patterns', [])
        if match(a:diffNode['name'], pattern) >= 0
            return 1
        endif
    endfor
endfunction
function! s:ZFIgnoreAction_both(taskData, diffNode)
    for pattern in get(get(a:taskData, 'ZFIgnore_excludeState', {}), 'dir_patterns', [])
        if match(a:diffNode['name'], pattern) >= 0
            return 1
        endif
    endfor
    for pattern in get(get(a:taskData, 'ZFIgnore_excludeState', {}), 'file_patterns', [])
        if match(a:diffNode['name'], pattern) >= 0
            return 1
        endif
    endfor
endfunction

let s:ZFIgnoreTypeMap = {
            \   g:ZFDirDiff_T_DIR : function('s:ZFIgnoreAction_dir'),
            \   g:ZFDirDiff_T_FILE : function('s:ZFIgnoreAction_file'),
            \   g:ZFDirDiff_T_DIR_LEFT : function('s:ZFIgnoreAction_dir'),
            \   g:ZFDirDiff_T_DIR_RIGHT : function('s:ZFIgnoreAction_dir'),
            \   g:ZFDirDiff_T_FILE_LEFT : function('s:ZFIgnoreAction_file'),
            \   g:ZFDirDiff_T_FILE_RIGHT : function('s:ZFIgnoreAction_file'),
            \   g:ZFDirDiff_T_CONFLICT_DIR_LEFT : function('s:ZFIgnoreAction_both'),
            \   g:ZFDirDiff_T_CONFLICT_DIR_RIGHT : function('s:ZFIgnoreAction_both'),
            \ }
function! ZFDirDiff_excludeCheck_ZFIgnore(taskData, diffNode)
    call s:ZFIgnoreUpdate(a:taskData)
    return s:ZFIgnoreTypeMap[a:diffNode['type']](a:taskData, a:diffNode)
endfunction

" state in taskData: {
"   'ZFIgnore_excludeState' : {
"     'stateId' : N,
"     'dir_patterns' : [],
"     'file_patterns' : [],
"   },
" }
function! s:ZFIgnoreUpdate(taskData)
    if !empty(get(a:taskData, 'ZFIgnore_excludeState', {}))
                \ && a:taskData['ZFIgnore_excludeState']['stateId'] == s:ZFIgnoreStateId
        return
    endif
    let excludePatterns = ZFDirDiff_excludePattern(a:taskData['pathL'], a:taskData['pathR'])
    let a:taskData['ZFIgnore_excludeState'] = {
                \   'stateId' : s:ZFIgnoreStateId,
                \   'dir_patterns' : excludePatterns['dir_patterns'],
                \   'file_patterns' : excludePatterns['file_patterns'],
                \ }
endfunction

" return ignore patterns respect to fileL/fileR's gitignore
" return: {
"   'dir_patterns' : ['some_pattern'],
"   'file_patterns' : ['some_pattern'],
" }
function! ZFDirDiff_excludePattern(pathL, pathR)
    let dir_patterns = {}
    let file_patterns = {}

    " default ignore
    let ignore = ZFIgnoreGet(get(g:, 'ZFIgnoreOption_ZFDirDiff', {
                \   'bin' : 0,
                \   'media' : 0,
                \   'ZFDirDiff' : 1,
                \ }))
    for pattern in ignore['dir']
        let patternTmp = ZFIgnorePatternToRegexp(pattern)
        if !empty(patternTmp)
            let dir_patterns[patternTmp] = 1
        endif
    endfor
    for pattern in ignore['file']
        let patternTmp = ZFIgnorePatternToRegexp(pattern)
        if !empty(patternTmp)
            let file_patterns[patternTmp] = 1
        endif
    endfor

    " gitignore for each side
    let gitignoreItems = {
                \   'dir' : {},
                \   'file' : {},
                \ }
    let pathList = []
    let option = copy(get(g:, 'ZFIgnore_ignore_gitignore_detectOption', {}))
    let option['path'] = a:pathL
    call extend(pathList, ZFIgnoreDetectGitignore(option))
    let option['path'] = a:pathR
    call extend(pathList, ZFIgnoreDetectGitignore(option))
    for path in pathList
        call ZFIgnoreParseGitignore(gitignoreItems, path)
    endfor

    let gitignore = {
                \   'dir' : keys(gitignoreItems['dir']),
                \   'file' : keys(gitignoreItems['file']),
                \   'dir_filtered' : [],
                \   'file_filtered' : [],
                \ }
    call ZFIgnoreFilterApply(gitignore)
    for pattern in gitignore['dir']
        let patternTmp = ZFIgnorePatternToRegexp(pattern)
        if !empty(patternTmp)
            let dir_patterns[patternTmp] = 1
        endif
    endfor
    for pattern in gitignore['file']
        let patternTmp = ZFIgnorePatternToRegexp(pattern)
        if !empty(patternTmp)
            let file_patterns[patternTmp] = 1
        endif
    endfor

    return {
                \   'dir_patterns' : keys(dir_patterns),
                \   'file_patterns' : keys(file_patterns),
                \ }
endfunction

