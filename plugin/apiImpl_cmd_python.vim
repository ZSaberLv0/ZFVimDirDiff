
" how the python impl improve performance:
" the python process is started and cached as job pool,
" each job only perform ZFJobSend to the python process,
" reduce call to ZFJobStart
" (generally, job_start cost a lot of time to start new process)

function! ZFDirDiff_python_available()
    return !empty(g:ZFDirDiff_python)
                \ && exists('*ZFJobAvailable') && ZFJobAvailable()
endfunction

function! ZFDirDiffCmd_listDir_python(absPath)
    return {
                \   'jobCmd' : ZFJobFunc(function('ZFDirDiff_python_listDirJob'), [a:absPath]),
                \ }
endfunction
function! ZFDirDiffCmd_listFile_python(absPath)
    return {
                \   'jobCmd' : ZFJobFunc(function('ZFDirDiff_python_listFileJob'), [a:absPath]),
                \ }
endfunction
function! ZFDirDiffCmd_diff_python(absPathL, absPathR)
    return {
                \   'jobCmd' : ZFJobFunc(function('ZFDirDiff_python_diffJob'), [a:absPathL, a:absPathR]),
                \ }
endfunction

" ============================================================
if !exists('s:state')
    " state: {
    "   'pool' : [
    "     {...}, // jobStatus of python process
    "   ],
    "   'pending' : [
    "     {
    "       'cmd' : 'listDir/listFile/diff',
    "       'pathL' : 'some_path',
    "       'pathR' : 'some_path',
    "       'ownerJob' : {...}, // jobStatus of owner job
    "     },
    "   ],
    "   'running' : N, // running pyJob count
    " }
    "
    " in each owner jobStatus: {
    "   'jobImplData' : {
    "     'ZFDirDiff_python_pyJob' : {...}, // the associate python job, may not exist if not running
    "   },
    " }
    " in each python jobStatus: {
    "   'jobImplData' : {
    "     'ZFDirDiff_python_ownerJob' : {...}, // the associate owner job, empty if not running
    "     'ZFDirDiff_python_cmd' : 'listDir/listFile/diff',
    "   },
    " }
    let s:state = {
                \   'pool' : [],
                \   'pending' : [],
                \   'running' : 0,
                \ }
endif

function! ZFDirDiff_python_pyJob_onOutput(pyJob, textList, type)
    let ownerJob = a:pyJob['jobImplData']['ZFDirDiff_python_ownerJob']
    let ownerJobId = get(ownerJob, 'jobId', -1)
    if ownerJobId == -1
        return
    endif

    if a:pyJob['jobImplData']['ZFDirDiff_python_cmd'] != 'diff'
        let textListNew = []
        let finished = 0
        for text in a:textList
            let tmp = split(text, "\t")
            if empty(tmp)
                continue
            elseif tmp[0] != ownerJobId
                return
            endif
            if len(tmp) == 1
                let finished = 1
            else
                call add(textListNew, tmp[1])
            endif
        endfor
        call ZFJobFallback_notifyOutput(ownerJob, textListNew, a:type)
        if finished
            call ZFJobFallback_notifyExit(a:pyJob['jobImplData']['ZFDirDiff_python_ownerJob'], '0')
        endif
    else
        for text in a:textList
            let tmp = split(text, "\t")
            if empty(tmp)
                continue
            elseif tmp[0] != ownerJobId
                return
            endif
            if tmp[1] == '0' || tmp[1] == '1' || tmp[1] == '2'
                call ZFJobFallback_notifyExit(a:pyJob['jobImplData']['ZFDirDiff_python_ownerJob'], tmp[1])
                return
            endif
        endfor
    endif
endfunction

function! s:obtainPool(ownerJob, cmd)
    for pyJob in s:state['pool']
        if empty(pyJob['jobImplData']['ZFDirDiff_python_ownerJob'])
            let pyJob['jobImplData']['ZFDirDiff_python_ownerJob'] = a:ownerJob
            let pyJob['jobImplData']['ZFDirDiff_python_cmd'] = a:cmd
            let a:ownerJob['jobImplData']['ZFDirDiff_python_pyJob'] = pyJob
            let pyJob['jobOutput'] = []
            return pyJob
        endif
    endfor
    if len(s:state['pool']) < get(g:, 'ZFDirDiff_python_poolSize', 8)
        let pyJobId = ZFJobStart({
                    \   'jobCmd' : printf('%s "%s/apiImpl.py"', g:ZFDirDiff_python, g:ZFDirDiffCmd_scriptPath),
                    \   'onOutput' : function('ZFDirDiff_python_pyJob_onOutput'),
                    \   'jobEncoding' : (has('win32') || has('win64')) && !has('unix') ? ZFJobImplGetWindowsEncoding() : '',
                    \ })
        let pyJob = ZFJobStatus(pyJobId)
        let pyJob['jobImplData']['ZFDirDiff_python_ownerJob'] = a:ownerJob
        let pyJob['jobImplData']['ZFDirDiff_python_cmd'] = a:cmd
        let a:ownerJob['jobImplData']['ZFDirDiff_python_pyJob'] = pyJob
        let pyJob['jobOutput'] = []
        call add(s:state['pool'], pyJob)
        return pyJob
    endif
    return {}
endfunction

function! s:runNext()
    if empty(s:state['pending'])
        if s:state['running'] == 0
            call s:pyJobCleanup()
        endif
        return
    endif
    let pending = remove(s:state['pending'], 0)
    if pending['cmd'] == 'listDir'
        call ZFDirDiff_python_listDirJob(pending['pathL'], pending['ownerJob'])
    elseif pending['cmd'] == 'listFile'
        call ZFDirDiff_python_listFileJob(pending['pathL'], pending['ownerJob'])
    elseif pending['cmd'] == 'diff'
        call ZFDirDiff_python_diffJob(pending['pathL'], pending['pathR'], pending['ownerJob'])
    endif
endfunction

function! s:pyJobCleanup()
    if get(s:, 'pyJobClearnupTaskId', -1) != -1
        call ZFJobTimerStop(s:pyJobClearnupTaskId)
    endif
    let s:pyJobClearnupTaskId = ZFJobTimerStart(get(g:, 'ZFDirDiff_python_autoCleanup', 5000), function('ZFDirDiff_python_pyJobCleanup'))
endfunction
function! ZFDirDiff_python_pyJobCleanup(...)
    let s:pyJobClearnupTaskId = -1
    if empty(s:state['pending']) && s:state['running'] == 0
        let pool = s:state['pool']
        let s:state['pool'] = []
        for pyJob in pool
            call ZFJobStop(pyJob['jobId'])
        endfor
    endif
endfunction

function! ZFDirDiff_python_ownerJob_notifyStop(ownerJob, exitCode)
    let pending = index(s:state['pending'], a:ownerJob)
    if pending >= 0
        call remove(s:state['pending'], pending)
    endif
    let pyJob = get(a:ownerJob['jobImplData'], 'ZFDirDiff_python_pyJob', {})
    if !empty(pyJob)
        let a:ownerJob['jobImplData']['ZFDirDiff_python_pyJob'] = {}
        let pyJob['jobImplData']['ZFDirDiff_python_ownerJob'] = {}
        let pyJob['jobImplData']['ZFDirDiff_python_cmd'] = ''
    endif

    let s:state['running'] -= 1
    call s:runNext()
endfunction

function! ZFDirDiff_python_listDirJob(path, ownerJob)
    let pyJob = s:obtainPool(a:ownerJob, 'listDir')
    if !empty(pyJob)
        let s:state['running'] += 1
        call ZFJobSend(pyJob['jobId'], printf("%s\tlistDir\t%s\n", a:ownerJob['jobId'], a:path))
    else
        call add(s:state['pending'], {
                    \   'cmd' : 'listDir',
                    \   'pathL' : a:path,
                    \   'ownerJob' : a:ownerJob,
                    \ })
    endif
    return {'notifyStop' : 'ZFDirDiff_python_ownerJob_notifyStop'}
endfunction
function! ZFDirDiff_python_listFileJob(path, ownerJob)
    let pyJob = s:obtainPool(a:ownerJob, 'listFile')
    if !empty(pyJob)
        let s:state['running'] += 1
        call ZFJobSend(pyJob['jobId'], printf("%s\tlistFile\t%s\n", a:ownerJob['jobId'], a:path))
    else
        call add(s:state['pending'], {
                    \   'cmd' : 'listFile',
                    \   'pathL' : a:path,
                    \   'ownerJob' : a:ownerJob,
                    \ })
    endif
    return {'notifyStop' : 'ZFDirDiff_python_ownerJob_notifyStop'}
endfunction
function! ZFDirDiff_python_diffJob(pathL, pathR, ownerJob)
    let pyJob = s:obtainPool(a:ownerJob, 'diff')
    if !empty(pyJob)
        let s:state['running'] += 1
        call ZFJobSend(pyJob['jobId'], printf("%s\tdiff\t%s\t%s\n", a:ownerJob['jobId'], a:pathL, a:pathR))
    else
        call add(s:state['pending'], {
                    \   'cmd' : 'diff',
                    \   'pathL' : a:pathL,
                    \   'pathR' : a:pathR,
                    \   'ownerJob' : a:ownerJob,
                    \ })
    endif
    return {'notifyStop' : 'ZFDirDiff_python_ownerJob_notifyStop'}
endfunction

