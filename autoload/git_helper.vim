
function! git_helper#show_commit_under_cursor()
  let commit=expand('<cword>')
  new
  exe 'read!git show --stat --patch '.commit
  goto
  delete
  set ft=git buftype=nofile
  map <buffer> b <C-b><C-g>
  map <buffer> q :q<CR>
  map <buffer> <space> <C-f><C-g>
endfunction

function! git_helper#show_file(file_expr)
  let cmd = 'git show '
  if a:file_expr !~ ':'
    let cmd .= ':'
  endif
  let cmd .= shellescape(a:file_expr)
  %delete
  exe 'read!'.cmd
  goto
  delete
  set buftype=nofile
endfunction

