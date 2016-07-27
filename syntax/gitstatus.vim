if !has("syntax") || !exists("g:syntax_on")
  finish
endif

syn match gitstatusHeader /^git .*/
syn region gitstatusError start='git: ERROR: ' end='$'

syn region gitstatusVersioned start='^[ MADRCU?]\{1,2\}\s' end='$' contains=gitstatusAddedFlag,gitstatusModifiedFlag,gitstatusRemovedFlag,gitstatusRenameSign,gitstatusError
syn region gitstatusUnknown start='^\(?\|[MADRCU?]?\)\s' end='$' contains=gitstatusUnknownFlag
syn match gitstatusAddedFlag contained /^.\?\zsA/
syn match gitstatusRemovedFlag contained /^.\?\zsD/
syn match gitstatusModifiedFlag contained /^.\?\zsM/
syn match gitstatusRenameSign contained / -> /
syn match gitstatusUnknownFlag contained /^.\?\zs?/

syn region gitstatusConflict start='^C  ' end='$' contains=gitstatusConflictType
syn region gitstatusConflictType start='^C  ' end=' in ' contains=gitstatusConflictFlag
syn match gitstatusConflictFlag contained /^C/

syn region gitstatusPending start='^P[. ]' end='$' contains=gitstatusPendingHeader keepend
syn region gitstatusPendingHeader contained start='^P[. ]' end='\d\{4\}-\d\{2\}-\d\{2\}' contains=gitstatusPendingFlag,gitstatusPendingDate keepend
syn match gitstatusPendingFlag contained /^P[. ]/
syn match gitstatusPendingDate contained /\d\{4\}-\d\{2\}-\d\{2\}/

hi def link gitstatusHeader Label
hi def link gitstatusError ErrorMsg

hi def link gitstatusVersioned Normal
hi def link gitstatusUnknown Comment
hi def link gitstatusAddedFlag DiffAdd
hi def link gitstatusRemovedFlag DiffDelete
hi def link gitstatusModifiedFlag DiffChange
hi def link gitstatusRenameSign Special
hi def link gitstatusUnknownFlag SpecialChar

hi def link gitstatusConflict Normal
hi def link gitstatusConflictType Type
hi def link gitstatusConflictFlag Error

hi def link gitstatusPending Comment
hi def link gitstatusPendingFlag Todo
hi def link gitstatusPendingHeader Statement
hi def link gitstatusPendingDate Number
