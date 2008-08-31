
rubyfile $USERVIM/autoload/rb_align.rb

ruby << EOF

def align_range(left, pre_match, surround_pre, delim_match, surround_post, post_match, range = nil)

  b = VIM::Buffer.current
  s = VIM::evaluate('a:firstline').to_i
  e = VIM::evaluate('a:lastline').to_i

  align(b, left, pre_match, surround_pre, delim_match, surround_post, post_match, s, e, range)

end

EOF

function! rb_align#AlignLeftEqual() range
  ruby align_range(true, '\s+|[^=<>+-]', ' ', '=', ' ', '\s*')
endfunction

function! rb_align#AlignLeftEqual_operator(type)
  :'[,']call rb_align#AlignLeftEqual()
endfunction

function! rb_align#AlignLeftComma() range
  ruby align_range(true, '\s*', '', ',', ' ', '\s*')
endfunction

function! rb_align#AlignLeftComma_operator(type)
  :'[,']call rb_align#AlignLeftComma()
endfunction

function! rb_align#AlignRightComma() range
  ruby align_range(false, '\s*', '', ',', ' ', '\s*')
endfunction

function! rb_align#AlignRightComma_operator(type)
  :'[,']call rb_align#AlignRightComma()
endfunction

function! rb_align#AlignDec() range
  ruby align_range(true, '(\b(static|const|volatile|enum|struct|union)\b\s+)*\w+\s*', ' ', ['\**', 3], '', '\s*', 0..0)
endfunction

function! rb_align#AlignDec_operator(type)
  :'[,']call rb_align#AlignDec()
endfunction

