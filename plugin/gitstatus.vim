
if !exists('g:gitstatus_unknowns')
  let g:gitstatus_unknowns = 1
endif

if !exists('g:gitstatus_vimdiff')
  let g:gitstatus_vimdiff = 0
endif

if !exists('g:gitstatus_staged')
  let g:gitstatus_staged = 0
endif

command! -nargs=* -complete=file GitStatus call gitstatus#start(<f-args>)

