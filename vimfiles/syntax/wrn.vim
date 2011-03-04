syn region obuildLogCommand start="^\d\+>" end="$"
syn region obuildLogBlock start="^--" end="$"
syn region obuildLogMessage start="^|" end="$"
syn region obuildLogWarning start="^\m+" end="$"
syn region obuildLogError start="^\m\*" end="$"

hi def link obuildLogBlock Statement
hi def link obuildLogCommand PreProc
hi def link obuildLogMessage Comment
hi def link obuildLogWarning Todo
hi def link obuildLogError Error
