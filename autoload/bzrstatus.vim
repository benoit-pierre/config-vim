
let s:bzrstatus_nextline = '^[-+R ][NDM][* ]\s'
let s:bzrstatus_matchline = '^\([-+R ][NDM][* ]\|[R?]  \|  \*\)\s\+\(.*\)$'

function! bzrstatus#clean_state()

  if exists('t:bzrstatus_diffbuf')
    call setbufvar(t:bzrstatus_diffbuf, '&diff', 0)
    unlet t:bzrstatus_diffbuf
  endif

  if exists('t:bzrstatus_tmpbuf')
    exe 'silent bd '.t:bzrstatus_tmpbuf
    unlet t:bzrstatus_tmpbuf
  endif

  if has('signs')
    exe ':sign unplace 2 buffer='.t:bzrstatus_buffer
  end

endfunction

function! bzrstatus#parse_entry_state()

  if line('.') > t:bzrstatus_msgline
    return []
  endif

  let l = getline('.')
  let m = matchlist(l, s:bzrstatus_matchline)

  if [] == m
    return []
  endif

  let renamed = (l[0] == 'R')
  let unknown = (l[0] == '?')
  let modified = (l[1] == 'M')
  let deleted = (l[1] == 'D')
  let added = (l[1] == 'N')

  let old_entry = m[2]

  if renamed

    let m = matchlist(old_entry, '^\(.*\) => \(.*$\)')

    if [] == m
      echoerr 'error parsing line: '.l
      return
    endif

    let old_entry = m[1]
    let new_entry = m[2]

  else

    let new_entry = old_entry

  endif

  let old_entry_fullpath = t:bzrstatus_tree.'/'.old_entry
  let new_entry_fullpath = t:bzrstatus_tree.'/'.new_entry

  return [renamed, unknown, modified, deleted, added, old_entry, old_entry_fullpath, new_entry, new_entry_fullpath]

endfunction

function! bzrstatus#diff_open()

  let s = bzrstatus#parse_entry_state()
  if [] == s
    return
  endif

  let [renamed, unknown, modified, deleted, added, old_entry, old_entry_fullpath, new_entry, new_entry_fullpath] = s

  call bzrstatus#clean_state()

  if has('signs')
    exe ':sign place 2 line='.line('.').' name=bzrstatus_sign_selection buffer='.t:bzrstatus_buffer
  end

  if 1 == winnr('$')
    new
  else
    wincmd k
  endif

  if modified || added || unknown
    " Open current tree version.
    exe 'edit '.fnameescape(new_entry_fullpath)
  endif

  if modified
    " Prepare for diff...
    let t:bzrstatus_diffbuf = bufnr('')
    let ft = &ft
    diffthis
    rightb vertical new
  elseif deleted
    " ...or original version display.
    enew
  endif

  if modified || deleted
    " Get original version from Bazaar.
    let t:bzrstatus_tmpbuf = bufnr('')
    exe 'file [BZR] '.fnameescape(old_entry)
    redraw
    exe 'silent read !'.g:bzrstatus_bzr.' cat '.shellescape(old_entry_fullpath)
    exe 'normal 1Gdd'
    setlocal buftype=nofile
  end

  if modified
    " Set filetype from original for correct syntax highlighting...
    let &ft = ft
    diffthis
  elseif deleted
    " ...or try to detect it
    filetype detect
  endif

  exe bufwinnr(t:bzrstatus_buffer).' wincmd w'

endfunction

function! bzrstatus#exec_bzr(cmd, files)

  setlocal modifiable

  if line('$') > t:bzrstatus_msgline
    exe 'silent '.(t:bzrstatus_msgline + 1).',$delete'
  endif

  let cmd = g:bzrstatus_bzr.' '.a:cmd

  if [] != a:files
    let files = map(a:files, 'shellescape(v:val)')
    let cmd = cmd.' '.join(files, ' ')
  endif

  call append(t:bzrstatus_msgline, [cmd, ''])
  redraw

  exe ':'.(t:bzrstatus_msgline + 2)
  let tf = tempname()
  exe 'silent !2>'.tf.' '.cmd
  exe 'read '.tf
  exe 'silent! '.t:bzrstatus_msgline.',$s/\s*\r//g'

  call bzrstatus#update(0)

endfunction

function! bzrstatus#add()

  let s = bzrstatus#parse_entry_state()
  if [] == s
    return
  endif

  let [renamed, unknown, modified, deleted, added, old_entry, old_entry_fullpath, new_entry, new_entry_fullpath] = s

  if !unknown
    return
  endif

  call bzrstatus#exec_bzr('add', [new_entry_fullpath])

endfunction

function! bzrstatus#commit()

  let s = bzrstatus#parse_entry_state()
  if [] == s
    return
  endif

  let [renamed, unknown, modified, deleted, added, old_entry, old_entry_fullpath, new_entry, new_entry_fullpath] = s

  if unknown
    return
  endif

  call bzrstatus#exec_bzr('ci', [new_entry_fullpath])

endfunction

function! bzrstatus#delete()

  let s = bzrstatus#parse_entry_state()
  if [] == s
    return
  endif

  let [renamed, unknown, modified, deleted, added, old_entry, old_entry_fullpath, new_entry, new_entry_fullpath] = s

  if unknown
    return
  endif

  call bzrstatus#exec_bzr('del', [new_entry_fullpath])

endfunction

function! bzrstatus#revert()

  let s = bzrstatus#parse_entry_state()
  if [] == s
    return
  endif

  let [renamed, unknown, modified, deleted, added, old_entry, old_entry_fullpath, new_entry, new_entry_fullpath] = s

  if !modified && !deleted && !renamed
    return
  endif

  call bzrstatus#exec_bzr('revert', [new_entry_fullpath])

endfunction

function! bzrstatus#shelve()

  let s = bzrstatus#parse_entry_state()
  if [] == s
    return
  endif

  let [renamed, unknown, modified, deleted, added, old_entry, old_entry_fullpath, new_entry, new_entry_fullpath] = s

  if unknown
    return
  endif

  call bzrstatus#exec_bzr('shelve', [new_entry_fullpath])

endfunction

function! bzrstatus#unshelve()

  call bzrstatus#exec_bzr('unshelve', [])

endfunction

function! bzrstatus#quit()

  call bzrstatus#clean_state()

  bwipeout

endfunction

function! bzrstatus#update(all)

  call bzrstatus#clean_state()

  setlocal modifiable

  if !a:all && exists('t:bzrstatus_msgline')
    exe 'silent 1,'.(t:bzrstatus_msgline - 1).'delete'
  else
    silent %delete
  endif

  let cmd = g:bzrstatus_bzr.' status -S '.shellescape(t:bzrstatus_path)
  call append(0, cmd)
  redraw

  :2
  exe 'silent read !'.cmd

  let l = line('.')
  call append(l, '')
  let t:bzrstatus_msgline = l + 1

  :2
  call search(s:bzrstatus_nextline, 'eW')

  setlocal nomodifiable

endfunction

function! bzrstatus#start(...)

  if a:0
    let path = a:1
  else
    let path = '.'
  end

  let t:bzrstatus_path = fnamemodify(path, ':p')
  let t:bzrstatus_tree = system(g:bzrstatus_bzr.' root '.shellescape(t:bzrstatus_path))[0:-2]

  silent botright split new
  setlocal buftype=nofile ft=bzrstatus fenc=utf-8
  exe 'file '.fnameescape(t:bzrstatus_tree)

  let t:bzrstatus_buffer = bufnr('')

  if has('signs')
    sign define bzrstatus_sign_selection text=>> texthl=Search linehl=Search
    sign define bzrstatus_sign_start
    exe ':sign place 1 line=1 name=bzrstatus_sign_start buffer='.t:bzrstatus_buffer
  endif

  call bzrstatus#update(1)

  nnoremap <silent> <buffer> <2-Leftmouse> :call bzrstatus#diff_open()<CR>
  nnoremap <silent> <buffer> <CR> :call bzrstatus#diff_open()<CR>
  nnoremap <silent> <buffer> A :call bzrstatus#add()<CR>
  nnoremap <silent> <buffer> C :call bzrstatus#commit()<CR>
  nnoremap <silent> <buffer> D :call bzrstatus#delete()<CR>
  nnoremap <silent> <buffer> R :call bzrstatus#revert()<CR>
  nnoremap <silent> <buffer> S :call bzrstatus#shelve()<CR>
  nnoremap <silent> <buffer> U :call bzrstatus#unshelve()<CR>
  nnoremap <silent> <buffer> q :call bzrstatus#quit()<CR>
  nnoremap <silent> <buffer> u :call bzrstatus#update(1)<CR>

endfunction

