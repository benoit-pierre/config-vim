
" To prevent bad indentation of comments.
setlocal comments=sl:/*,m:**,ex:*/,sl:/**,m:**,ex:*/

" Correct indent level, tab replaced by 4 spaces.
setlocal expandtab
setlocal shiftwidth=4
setlocal softtabstop=4

" Indentation settings.
set cinoptions=>1s,c0,(0,u0,g1s,h1s,:0,=1s

" Highlight trailing white spaces, tabs.
setlocal list

" Dictionary for completion.
setlocal dictionary+=$USERVIM/dictionaries/c.dic

" Activate doxygen syntax highlighting.
let g:load_doxygen_syntax=1

" Make matchit work for:
" # if foo
" #  ifdef arg
" #  elif defined(bar)
" #  else
" # endif
let b:match_words .= ',#\s*if:^#\s*el\(se\|if\):#\s*endif'

