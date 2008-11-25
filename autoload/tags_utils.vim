
if exists('g:loaded_tags_utils_autoload') || &cp
 finish
endif
let g:loaded_tags_utils_autoload = 1

" Find a file, first using findfile(), and if no results is found and a cscope
" connection is available, using 'cscope find file'. If goto_line is not 0,
" then jump to line if its present (:xxx after the filename). If file_expr is
" not empty and goto_line is >1, then the :xxx directive must be present. If
" goto_line is >2, delete old buffer.
function! tags_utils#TagsFindFile(file_expr, goto_line)

  let line = 0

  let bufname = bufname('%')

  if empty(a:file_expr)

    " No file_expr passed as argument, use filename on the current cursor
    " position.

    let fname = expand('<cfile>')

    if a:goto_line

      let line = getline('.')[col('.') - 1 : ]
      let match = matchlist(line, '^\f\+:\(\d\+\)')

      if !empty(match)
        let line = str2nr(match[1])
      end

    endif

  else

    " Use file_expr argument.

    let fname = a:file_expr

    if a:goto_line

      let match = matchlist(fname, '^\(\f\+\):\(\d\+\)$')

      if empty(match)
        if a:goto_line > 1
          return
        end
      else
        let fname = match[1]
        let line = str2nr(match[2])
      endif

    endif

  endif

  let file = findfile(fname)

  if empty(file)
    if !cscope_connection()
      return
    endif
    silent! exe ':csc f f '.fname
  else
    silent! exe ':e '.file
  endif

  " Did it work, i.e. the buffer changed?
  if bufname !=# bufname('%')
    if a:goto_line > 2 && !empty(bufname)
      exec ":bdelete ".bufnr(bufname)
    endif
    file
    if line
      call cursor(line, 1)
    endif
  endif

endfunction

function! tags_utils#TagsFindInclude(reg, tag_pattern)

  let tags = taglist(a:tag_pattern)

  if empty(tags)
    return
  end

  let includes = []

  for tag in tags
    let include = tag['filename']
    if include !~ '\.hh\?$'
      continue
    endif
    if empty(a:reg)
      echo include
      continue
    endif
    let include = substitute(include, '.*[\\\/]', '', '')
    call setreg(a:reg, '#include "'.include."\"\n")
    return
  endfor

endfunction

" Remane all reference to a symbol using cscope. Based on:
" http://www.vim.org/scripts/script.php?script_id=2164
function! tags_utils#TagsRename()
  " store old buffer and restore later
  let stored_buffer = bufnr("%")

  " start refactoring
  let old_name = expand("<cword>")
  let new_name = input("new name: ",old_name)

  let cscope_out = system(&cscopeprg.' -L -d -F cscope.out -0 ' . old_name)
  let cscope_out_list = split(cscope_out, '\n')

  for cscope_line in cscope_out_list
    let cscope_line_split = split(cscope_line, ' ')
    let subs_file = cscope_line_split[0]
    let subs_lnr = cscope_line_split[2]
    let subs_buffer = bufnr(subs_file)

    if subs_buffer == -1
      exe 'edit '.subs_file
      let do_close = 1
      let subs_buffer = bufnr(subs_file)
    else
      let do_close = 0
    endif

    if subs_buffer != -1
      exe 'buffer '.subs_buffer
      exe subs_lnr.','.subs_lnr.'s/\<'.old_name.'\>/'.new_name.'/gc'
      exe 'write'
      if do_close == 1
        exe 'bd'
      endif
    endif
  endfor
  exe 'buffer '.stored_buffer
endfunction
