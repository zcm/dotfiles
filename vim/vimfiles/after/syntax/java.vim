" This fixes an issue with JDK 8 where the arrow operator -> is highlighted as
" an error (present in at least 7.4.589 and earlier).

syn clear javaError
syn match javaError "<<<\|\.\.\|=>\|||=\|&&=\|\*\/"

if exists("java_highlight_functions")
    syn match javaFuncDef "[^-]->"
endif
