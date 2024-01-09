
if !exists('*ZFDirDiffAPIImpl_init')
    " start new diff task
    " when any node in taskData changed, you should call ZFDirDiffAPI_dataChanged() to update UI
    function! ZFDirDiffAPIImpl_init(taskData)
        return ZFDirDiffAPIImpl_job_init(a:taskData)
    endfunction

    function! ZFDirDiffAPIImpl_cleanup(taskData)
        return ZFDirDiffAPIImpl_job_cleanup(a:taskData)
    endfunction

    " param: which node to update, or {} to update all
    " note: may called during previous diff task
    function! ZFDirDiffAPIImpl_update(taskData, ...)
        return ZFDirDiffAPIImpl_job_update(a:taskData, get(a:, 1, {}))
    endfunction
endif

