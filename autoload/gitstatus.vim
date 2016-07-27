
let s:gitstatus_mappings =
      \ {
      \ 'quit'     : [ 'q', ],
      \ 'update'   : [ 'u', ],
      \ 'diff_open': [ '<2-Leftmouse>', '<CR>' ],
      \ 'exec'     : [ '!' ],
      \ 'git'      : [ 'e' ],
      \ 'info'     : [ 'i' ],
      \ 'log'      : [ 'l' ],
      \ 'missing'  : [ 'M' ],
      \
      \ 'add'     : [ 'A' ],
      \ 'commit'  : [ 'C' ],
      \ 'del'     : [ 'D' ],
      \ 'extmerge': [ 'M' ],
      \ 'reset'   : [ 'r' ],
      \ 'revert'  : [ 'R' ],
      \ 'shelve'  : [ 'S' ],
      \ 'uncommit': [ 'B' ],
      \ 'unshelve': [ 'U' ],
      \
      \ 'toggle_unknowns': [ 'o?' ],
      \ 'toggle_vimdiff': [ 'ov' ],
      \ 'toggle_staged': [ 'os' ],
      \
      \ 'toggle_tag'  : [ '<Space>' ],
      \ 'tag_added'   : [ 'ma' ],
      \ 'tag_deleted' : [ 'md' ],
      \ 'tag_modified': [ 'mm' ],
      \ 'tag_renamed' : [ 'mr' ],
      \ 'tag_unknown' : [ 'mu' ],
      \ }

if exists('g:gitstatus_mappings')
  call extend(s:gitstatus_mappings, g:gitstatus_mappings)
endif

let s:gitstatus_nextline = '^\([ MADRCU?]\{1,2\}\)'
let s:gitstatus_matchline = s:gitstatus_nextline.'\s\+\(.*\)$'

let s:gitstatus_op_criterion =
      \ {
      \ 'add'     : 'deleted || modified || renamed || unknown',
      \ 'commit'  : '!unknown',
      \ 'del'     : '!unknown && !deleted && !added',
      \ 'extmerge': 'modified',
      \ 'revert'  : 'modified || deleted || renamed || added',
      \ 'shelve'  : '!unknown',
      \ }

let s:gitstatus_op_options =
      \ {
      \ 'commit'  : [ '-v' ],
      \ 'log'     : [ '--line' ],
      \ 'missing' : [ '--line' ],
      \ }

if exists('g:gitstatus_op_options')
  call extend(s:gitstatus_op_options, g:gitstatus_op_options)
endif

let s:gitstatus_op_confirm =
      \ {
      \ 'revert'  : 1,
      \ 'unshelve': 1,
      \ }

let s:gitstatus_op_update =
      \ {
      \ 'add'        : 1,
      \ 'clean-tree' : 1,
      \ 'commit'     : 1,
      \ 'del'        : 1,
      \ 'ignore'     : 1,
      \ 'import'     : 1,
      \ 'merge'      : 1,
      \ 'mkdir'      : 1,
      \ 'mv'         : 1,
      \ 'patch'      : 1,
      \ 'pull'       : 1,
      \ 'reconfigure': 2,
      \ 'reset'      : 1,
      \ 'resolve'    : 1,
      \ 'revert'     : 1,
      \ 'shelve'     : 1,
      \ 'switch'     : 2,
      \ 'uncommit'   : 1,
      \ 'unshelve'   : 1,
      \ 'update'     : 1,
      \ }

if exists('g:gitstatus_op_confirm')
  call extend(s:gitstatus_op_confirm, g:gitstatus_op_confirm)
endif

if !exists('g:gitstatus_use_input')
  let g:gitstatus_use_input = has('bpierre')
endif

function! gitstatus#tag_line(ln)

  if has_key(t:gitstatus_tagged, a:ln)
    return
  endif

  let t:gitstatus_tagged[a:ln] = 1

  if has('signs')
    if a:ln == t:gitstatus_selection
      let sign = 'gitstatus_sign_selection_tag'
    else
      let sign = 'gitstatus_sign_tag'
    endif
    exe ':sign place '.a:ln.' line='.a:ln.' name='.sign.' buffer='.t:gitstatus_buffer
  endif

endfunction

function! gitstatus#untag_line(ln)

  if !has_key(t:gitstatus_tagged, a:ln)
    return
  endif

  call remove(t:gitstatus_tagged, a:ln)

  if has('signs')
    if a:ln == t:gitstatus_selection
      exe ':sign place '.a:ln.' line='.a:ln.' name=gitstatus_sign_selection buffer='.t:gitstatus_buffer
    else
      exe ':sign unplace '.a:ln.' buffer='.t:gitstatus_buffer
    endif
  endif

endfunction

function! gitstatus#clear_tagged()

  if has('signs')
    for ln in keys(t:gitstatus_tagged)
      call gitstatus#untag_line(ln)
    endfor
  endif

  let t:gitstatus_tagged = {}

endfunction

function! gitstatus#select_line(ln)

  if has('signs')
    if has_key(t:gitstatus_tagged, a:ln)
      let sign = 'gitstatus_sign_selection_tag'
    else
      let sign = 'gitstatus_sign_selection'
    endif
    exe ':sign place '.a:ln.' line='.a:ln.' name='.sign.' buffer='.t:gitstatus_buffer
  end

  let t:gitstatus_selection = a:ln

endfunction

function! gitstatus#unselect_line()

  if 0 == t:gitstatus_selection
    return
  endif

  if has('signs')
    if has_key(t:gitstatus_tagged, t:gitstatus_selection)
      exe ':sign place '.t:gitstatus_selection.' line='.t:gitstatus_selection.' name=gitstatus_sign_tag buffer='.t:gitstatus_buffer
    else
      exe ':sign unplace '.t:gitstatus_selection.' buffer='.t:gitstatus_buffer
    endif
  endif

  let t:gitstatus_selection = 0

endfunction

function! gitstatus#clean_tmpbufs()

  if exists('t:gitstatus_tmpbuf1')
    exe 'silent bwipeout '.t:gitstatus_tmpbuf1
    unlet t:gitstatus_tmpbuf1
  endif

endfunction

function! gitstatus#clean_state(clear_tagged)

  if exists('t:gitstatus_diffbuf')
    call setbufvar(t:gitstatus_diffbuf, '&diff', 0)
    set nodiff noscrollbind
    unlet t:gitstatus_diffbuf
  endif

  call gitstatus#unselect_line()

  if a:clear_tagged
    call gitstatus#clear_tagged()
  end

endfunction

function! gitstatus#parse_entry_state(ln)

  if a:ln <= 2 || a:ln >= t:gitstatus_msgline
    return []
  endif

  let l = getline(a:ln)
  let m = matchlist(l, s:gitstatus_matchline)

  if [] == m
    return []
  endif

  let added   = (l[0] == 'A')
  let renamed = (l[0] == 'R')
  let unknown = (l[0] == '?')
  let modified = (l[0] == 'M' || l[1] == 'M' || l[1] == 'U')
  let deleted  = (l[0] == 'D' || l[1] == 'D')

  let old_entry = m[2]

  if renamed

    let m = matchlist(old_entry, '^\(.*\) -> \(.*$\)')

    if [] == m
      echoerr 'error parsing line: '.l
      return
    endif

    let old_entry = m[1]
    let new_entry = m[2]

  else

    let new_entry = old_entry

  endif

  return [renamed, unknown, modified, deleted, added, old_entry, new_entry]

endfunction

function! gitstatus#filter_entries(range, criterion)

  let files = []

  for ln in a:range

    let s = gitstatus#parse_entry_state(ln)
    if [] == s
      continue
    endif

    let [renamed, unknown, modified, deleted, added, old_entry, new_entry] = s
    if !eval(a:criterion)
      continue
    endif

    let files += [new_entry]

  endfor

  return files

endfunction

function! gitstatus#showdiff()

  let ln = line('.')

  let s = gitstatus#parse_entry_state(ln)
  if [] == s
    return
  endif

  let [renamed, unknown, modified, deleted, added, old_entry, new_entry] = s

  let new_entry_fullpath = t:gitstatus_tree.'/'.new_entry

  call gitstatus#clean_state(0)

  call gitstatus#select_line(ln)

  if 1 == winnr('$')
    new
  else
    wincmd k
    enew
  endif

  call gitstatus#clean_tmpbufs()

  let vimdiff = modified && t:gitstatus_vimdiff

  if vimdiff || added || unknown
    " Open current tree version.
    exe 'edit '.fnameescape(new_entry_fullpath)
  endif

  if vimdiff
    " Prepare for diff...
    let t:gitstatus_diffbuf = bufnr('')
    let ft = &ft
    let fenc = &fenc
    diffthis
    rightb vertical new
  elseif deleted
    " ...or original version display.
    enew
  endif

  if vimdiff || modified || deleted
    setlocal buftype=nofile noswapfile
    let t:gitstatus_tmpbuf1 = bufnr('')
    exe 'file [GIT'.t:git_num.'] '.fnameescape(old_entry)
    redraw
    if vimdiff || deleted
      " Get original version.
      let cmd = 'git show '
      if 'HEAD' == t:gitstatus_revision && !t:gitstatus_staged
        let cmd .= ':0'
      else
        let cmd .= t:gitstatus_revision
      endif
      let cmd .= ':'.fnameescape(old_entry)
      exe 'silent read! '.cmd
      " if 'dos' == b:gitstatus_fileformat
        " silent! %s/\r$/
        " setl ff=dos
      " endif
    else
      " Get diff.
      let cmd = 'git diff '
      if 'HEAD' == t:gitstatus_revision && !t:gitstatus_staged
      else
        let cmd .= t:gitstatus_revision.' '
      endif
      let cmd .= '-- '.fnameescape(new_entry)
      exe 'silent read! '.cmd
      set ft=diff
    endif
    exe 'normal 1Gdd'
  end

  if vimdiff
    " Set filetype from original for correct syntax highlighting...
    let &ft = ft
    let &fenc = fenc
    diffthis
  elseif deleted
    " ...or try to detect it
    filetype detect
  endif

  exe bufwinnr(t:gitstatus_buffer).' wincmd w'

endfunction

function! gitstatus#diff_open()
  call gitstatus#showdiff()
endfunction

function! gitstatus#git_run(cmd, update)

  setlocal modifiable

  if line('$') > t:gitstatus_msgline
    exe 'silent '.(t:gitstatus_msgline + 1).',$delete'
  endif

  let cmd = 'git '
  if 3 == type(a:cmd)
    let cmd .= join(a:cmd, ' ')
  else
    let cmd .= a:cmd
  endif

  call append(t:gitstatus_msgline, [cmd, ''])
  exe ':'.(t:gitstatus_msgline + 2)
  redraw

  " Deactivate cursor line/column during command execution.
  let cursorline = &l:cursorline
  let cursorcolumn = &l:cursorcolumn
  setl nocursorline nocursorcolumn

  let git_cmd = 'git --no-pager '
  if 3 == type(a:cmd)
    let git_cmd .= join(map(a:cmd, 'fnameescape(v:val)'), ' ')
  else
    let git_cmd .= a:cmd
  endif
  if has("gui_running")
    " let cmd = '!xterm -title git -e env TMUX= tmux new-session '
    let cmd = '!term -t '."'".git_cmd."' "
  else
    let cmd = '!tmux new-window '
  end
  let cmd .= "'".'tmux pipe-pane -t $TMUX_PANE "cat >'.t:gitstatus_tempfile.'"; '.git_cmd."'"
  exe 'silent '.cmd
  exe 'silent read '.t:gitstatus_tempfile
  redraw

  " Restore cursor line/column.
  let &l:cursorline = cursorline
  let &l:cursorcolumn = cursorcolumn
  " Hack to make sure term is reseted to raw (and force a full redraw).
  let &term = &term

  setlocal nomodifiable

  if a:update
    call gitstatus#update_buffer(a:update)
  endif

endfunction

function! gitstatus#toggle_tag()

  let ln = line('.')
  if ln <= 2 || ln >= t:gitstatus_msgline
    return
  endif

  if has_key(t:gitstatus_tagged, ln)
    call gitstatus#untag_line(ln)
  else
    call gitstatus#tag_line(ln)
  endif

  call gitstatus#next_entry(0, 1)

endfunction

function! gitstatus#git_op(tagged, firstl, lastl, op)

  let criterion = get(s:gitstatus_op_criterion, a:op, '')

  if '' != criterion

    if a:tagged
      let r = keys(t:gitstatus_tagged)
    else
      let r = range(a:firstl, a:lastl)
    endif

    if [] == r
      return
    endif

    let files = gitstatus#filter_entries(r, criterion)
    if [] == files
      return
    endif

  else

    let files = []

  endif

  let options = get(s:gitstatus_op_options, a:op, [])
  let confirm = get(s:gitstatus_op_confirm, a:op, 0)
  let update = get(s:gitstatus_op_update, a:op, 0)

  let cmd = a:op

  if [] != files
    let cmd .= ' '.join(files, ' ')
  endif

  if confirm && 2 == confirm(cmd, "&Yes\n&No", 2)
    setlocal nomodifiable
    return
  endif

  call gitstatus#git_run([a:op] + options + files, update)

endfunction

function! gitstatus#add(tagged) range
  call gitstatus#git_op(a:tagged, a:firstline, a:lastline, 'add')
endfunction

function! gitstatus#commit(tagged) range
  call gitstatus#git_op(a:tagged, a:firstline, a:lastline, 'commit')
endfunction
function! gitstatus#del(tagged) range
  call gitstatus#git_op(a:tagged, a:firstline, a:lastline, 'del')
endfunction

function! gitstatus#extmerge(tagged) range
  call gitstatus#git_op(a:tagged, a:firstline, a:lastline, 'extmerge')
endfunction

function! gitstatus#reset(tagged) range
  call gitstatus#git_op(a:tagged, a:firstline, a:lastline, 'reset')
endfunction

function! gitstatus#revert(tagged) range
  call gitstatus#git_op(a:tagged, a:firstline, a:lastline, 'checkout')
endfunction

function! gitstatus#shelve(tagged) range
  call gitstatus#git_op(a:tagged, a:firstline, a:lastline, 'shelve')
endfunction

function! gitstatus#toggle_unknowns()
  let t:gitstatus_unknowns = !t:gitstatus_unknowns
  call gitstatus#update()
endfunction

function! gitstatus#toggle_vimdiff()
  let t:gitstatus_vimdiff = !t:gitstatus_vimdiff
endfunction

function! gitstatus#toggle_staged()
  let t:gitstatus_staged = !t:gitstatus_staged
endfunction

function! gitstatus#uncommit()
  call gitstatus#git_op(0, 0, 0, 'uncommit')
endfunction

function! gitstatus#unshelve()
  call gitstatus#git_op(0, 0, 0, 'unshelve')
endfunction

function! gitstatus#info()
  call gitstatus#git_op(0, 0, 0, 'info')
endfunction

function! gitstatus#log()
  call gitstatus#git_op(0, 0, 0, 'log')
endfunction

function! gitstatus#missing()
  call gitstatus#git_op(0, 0, 0, 'missing')
endfunction

function! gitstatus#complete(arglead, cmdline, cursorpos)

  if !g:gitstatus_use_input
    let strip = strlen('BzrStatusBzr') + 1
    let cmdline = strpart(a:cmdline, strip)
    let cursorpos = a:cursorpos - strip
  else
    let cmdline = a:cmdline
    let cursorpos = a:cursorpos
  endif

  " python git().complete(
        " \ cmdline=vim.eval('cmdline'),
        " \ cursorpos=int(vim.eval('cursorpos')))

  return matches

endfunction

function! gitstatus#input()
  return input('git ', '', 'customlist,gitstatus#complete')
endfunction

function! gitstatus#git(cmdline)

  let args = split(a:cmdline)

  if empty(args)
    return
  endif

  let update = get(s:gitstatus_op_update, args[0], 0)

  call gitstatus#git_run(a:cmdline, update)

endfunction

function! gitstatus#get_entries(mode)

  if 'l' == a:mode
    let r = [line('.')]
  elseif 't' == a:mode
    let r = keys(t:gitstatus_tagged)
  elseif 'v' == a:mode
    let r = range(line("'<"), line("'>"))
  else
    return []
  endif

  let entries = gitstatus#filter_entries(r, '1')

  let s = ''

  for e in entries

    let es = shellescape(e)

    if es == "'".e."'"
      let s .= e.' '
    else
      let s .= es. ' '
    endif

  endfor

  return s

endfunction

function! gitstatus#quit()

  let buf = expand('<abuf>')
  if !buf
    let buf = bufnr('')
  endif

  call gitstatus#clean_state(1)
  call gitstatus#clean_tmpbufs()

  exe 'bwipeout '.buf

endfunction

function! gitstatus#tag(criterion, set)

  let cursor_save = getpos('.')[1:3]

  :2

  while gitstatus#next_entry(0, 0)

    let ln = line('.')

    let s = gitstatus#parse_entry_state(ln)
    if [] == s
      continue
    endif

    let [renamed, unknown, modified, deleted, added, old_entry, new_entry] = s
    if eval(a:criterion)
      if a:set
        call gitstatus#tag_line(ln)
      else
        call gitstatus#untag_line(ln)
      endif
    endif

  endwhile

  call cursor(cursor_save)

endfunction

function! gitstatus#next_entry(from_top, wrap)

  if a:from_top
    :2
  else
    exe 'normal $'
  endif

  if search(s:gitstatus_nextline, 'eW', t:gitstatus_msgline)
    return 1
  endif

  if a:wrap
    :2
    return search(s:gitstatus_nextline, 'eW', t:gitstatus_msgline)
  endif

  return 0

endfunction

function! gitstatus#update_buffer(type)

  call gitstatus#clean_state(1)

  let t:gitstatus_tagged = {}

  setlocal modifiable

  if 1 < a:type
    " python git().update(update_file=True)
  endif

  if 3 > a:type && exists('t:gitstatus_msgline')
    exe 'silent 1,'.(t:gitstatus_msgline - 1).'delete'
  else
    silent %delete
  endif

  if 'HEAD' == t:gitstatus_revision
    let cmd = ['status', '--porcelain', '--short']
    if !t:gitstatus_unknowns
      let cmd += ['--untracked-files=no']
    endif
    if !t:gitstatus_unknowns
      let cmd += ['--staged']
    endif
  else
    let cmd = ['diff', '--find-renames', '--name-status', t:gitstatus_revision, '--']
  endif
  call append(0, 'git '.join(cmd, ' '))
  redraw

  :2
  exe 'silent read! git '.join(map(cmd, 'fnameescape(v:val)'), ' ')

  let l = line('.')
  call append(l, '')
  let t:gitstatus_msgline = l + 1

  :2
  call gitstatus#next_entry(1, 0)

  setlocal nomodifiable

endfunction

function! gitstatus#update()
  call gitstatus#update_buffer(3)
endfunction

function! gitstatus#start(...)

  let path = 0
  let revision = 'HEAD'

  let n = 0
  while 1
    if n >= len(a:000)
      break
    end
    let a = a:000[n]
    let n += 1
    if a =~ "^-"
      " option.
      if a =~ "^-[r]"
        if 'r' == a[1]
          let revision = a:000[n]
          let n += 1
          continue
        end
      end
      echoerr 'invalid option: '.a
      return
    else
      " argument.
      if 0 == path
        let path = a
        continue
      end
      echoerr 'invalid argument: '.a
      return
    end
  endwhile

  if 0 == path
    let path = '.'
  end

  let t:gitstatus_unknowns = g:gitstatus_unknowns
  let t:gitstatus_vimdiff = g:gitstatus_vimdiff
  let t:gitstatus_staged = g:gitstatus_staged
  let t:gitstatus_revision = revision
  let t:gitstatus_selection = 0
  let t:gitstatus_tagged = {}
  let t:gitstatus_mode = "l"
  let t:gitstatus_tempfile = tempname()
  exe 'silent !mkfifo '.t:gitstatus_tempfile

  let t:gitstatus_path = fnamemodify(path, ':p')
  let t:gitstatus_tree = t:gitstatus_path
  let t:git_num = bufnr('')

  silent botright split new
  setlocal buftype=nofile noswapfile ft=gitstatus fenc=utf-8

  exe 'lchdir '.fnameescape(t:gitstatus_tree)

  let t:gitstatus_buffer = bufnr('')

  let filename = '[GIT'.t:git_num.'] '.t:gitstatus_tree.' '.t:gitstatus_revision
  exe 'file '.fnameescape(filename)

  if has('signs')
    sign define gitstatus_sign_selection text=>> texthl=Search linehl=Search
    sign define gitstatus_sign_selection_tag text=!> texthl=Search
    sign define gitstatus_sign_tag text=!
    sign define gitstatus_sign_start
    exe ':sign place 1 line=1 name=gitstatus_sign_start buffer='.t:gitstatus_buffer
  endif

  if has('conceal') && exists(':AnsiEsc')
    exe 'AnsiEsc'
    runtime! syntax/gitstatus.vim
  endif

  call gitstatus#update_buffer(3)

  for name in [ 'quit', 'update', 'diff_open', 'info', 'log', 'missing', 'uncommit', 'unshelve', 'toggle_unknowns', 'toggle_vimdiff', 'toggle_staged', 'toggle_tag' ]
    for map in s:gitstatus_mappings[name]
      exe 'nnoremap <silent> <buffer> '.map.' :call gitstatus#'.name.'()<CR>'
    endfor
  endfor

  for map in s:gitstatus_mappings['toggle_tag']
    exe 'vnoremap <silent> <buffer> '.map.' :call gitstatus#toggle_tag()<CR>'
  endfor

  for name in [ 'add', 'commit', 'del', 'extmerge', 'reset', 'revert', 'shelve' ]
    for map in s:gitstatus_mappings[name]
      exe 'nnoremap <silent> <buffer> '.map.' :call gitstatus#'.name.'(0)<CR>'
      exe 'vnoremap <silent> <buffer> '.map.' :call gitstatus#'.name.'(0)<CR>'
      exe 'noremap <silent> <buffer> ,'.map.' :call gitstatus#'.name.'(1)<CR>'
    endfor
  endfor

  for name in [ 'added', 'deleted', 'modified', 'renamed', 'unknown' ]
    for map in s:gitstatus_mappings['tag_'.name]
      exe 'nnoremap <silent> <buffer> ,<Space>'.toupper(map).' :call gitstatus#tag("'.name.'", 1)<CR>'
      exe 'nnoremap <silent> <buffer> ,<Space>'.tolower(map).' :call gitstatus#tag("'.name.'", 0)<CR>'
    endfor
  endfor

  if !g:gitstatus_use_input
    for map in s:gitstatus_mappings['git']
      exe 'nnoremap <buffer> '.map.' :let t:gitstatus_mode="l"<CR>:BzrStatusBzr '
      exe 'vnoremap <buffer> '.map.' <Esc>:let t:gitstatus_mode="v"<CR>:BzrStatusBzr '
    endfor
  else
    for map in s:gitstatus_mappings['git']
      exe 'nnoremap <buffer> '.map.' :let t:gitstatus_mode="l"<Bar>call gitstatus#git(gitstatus#input())<CR>'
      exe 'vnoremap <buffer> '.map.' <Esc>:let t:gitstatus_mode="v"<Bar>call gitstatus#git(gitstatus#input())<CR>'
    endfor
  endif

  for map in s:gitstatus_mappings['exec']
    exe 'nnoremap <buffer> '.map.' :let t:gitstatus_mode="l"<CR>:!'
    exe 'vnoremap <buffer> '.map.' <Esc>:let t:gitstatus_mode="v"<CR>:!'
  endfor

  autocmd BufDelete <buffer> call gitstatus#quit()

  cnoremap <buffer> <C-R><C-E> <C-R>=gitstatus#get_entries(t:gitstatus_mode)<CR>
  cnoremap <buffer> <C-R><C-T> <C-R>=gitstatus#get_entries('t')<CR>

endfunction

if !g:gitstatus_use_input
  command! -nargs=* -complete=customlist,gitstatus#complete GitStatusGit call gitstatus#git(<q-args>)
endif

