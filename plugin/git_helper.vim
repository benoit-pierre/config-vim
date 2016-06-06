
autocmd! BufNewFile git:[^/]* nested call git_helper#show_file(substitute(bufname('%'), 'git:', '', ''))

