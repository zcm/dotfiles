function g
  set -l argcount (count $argv)
  if [ $argcount = "0" ]
    git
    return
  end
  set -l gcmd $argv[1]
  switch $argv[1]
    case s
      set gcmd "status"
    case st
      set gcmd "status"
    case sta
      set gcmd status
    case stat
      set gcmd status
    case stats
      set gcmd status
    case r
      set gcmd rebase
    case re
      set gcmd rebase
    case reb
      set gcmd rebase
    case ri
      set gcmd rebase -i
    case rei
      set gcmd rebase -i
    case ria
      set gcmd rebase -i --autosquash
    case p
      set gcmd pull
    case pu
      set gcmd pull
    case pr
      set gcmd pull --rebase
    case f
      set gcmd fetch
    case fe
      set gcmd fetch
    case fet
      set gcmd fetch
    case cm
      set gcmd commit
    case cma
      set gcmd commit --amend
    case co
      set gcmd checkout
    case cob
      set gcmd checkout -b
    case b
      set gcmd branch
    case br
      set gcmd branch
    case m
      set gcmd merge
    end
    if [ $argcount = "1" ]
      git $gcmd
    else
      git $gcmd $argv[2..-1]
    end
end
