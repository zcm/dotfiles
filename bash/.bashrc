# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Source the local rc, if it exists
if [ -f ~/.local_bashrc ]; then
  . ~/.local_bashrc
fi

# User specific aliases and functions

function bm {
  local STACK_ID=0
  local FOUND_ID=0
  local SEMICOUNT=
  if [[ "$1" == "-l" ]]; then
    IFS=';' read -ra ADDR <<< "$BM_DIRECTORYSTACK"
    for i in "${ADDR[@]}"; do
      echo $STACK_ID: $i
      STACK_ID=$((STACK_ID+1))
    done
  elif [[ "$1" == "-d" ]]; then
    if [[ "$2" =~ ^[0-9]+$ ]]; then
      IFS=';' read -ra ADDR <<< "$BM_DIRECTORYSTACK"
      BM_DIRECTORYSTACK=
      for i in "${ADDR[@]}"; do
        if [[ $STACK_ID -ne $2 ]]; then
          if [[ "$BM_DIRECTORYSTACK" == "" ]]; then
            BM_DIRECTORYSTACK="$i"
          else
            BM_DIRECTORYSTACK="$BM_DIRECTORYSTACK;$i"
          fi
        fi
        STACK_ID=$((STACK_ID+1))
      done
    else
      echo "error: must specify valid id to delete"
    fi
  elif [[ "$1" =~ ^[0-9]+$ ]]; then
    IFS=';' read -ra ADDR <<< "$BM_DIRECTORYSTACK"
    for i in "${ADDR[@]}"; do
      if [[ $STACK_ID -eq $1 ]]; then
        cd $i
        FOUND_ID=1
        break
      fi
      STACK_ID=$((STACK_ID+1))
    done
    if [[ $FOUND_ID -eq 0 ]]; then
      echo "error: bookmark id not in stack"
    fi
  elif [[ "$1" == "-c" ]]; then
    BM_DIRECTORYSTACK=
  elif [[ "$1" == "" ]]; then
    if [[ "$BM_DIRECTORYSTACK" != "" ]]; then
      BM_DIRECTORYSTACK="$BM_DIRECTORYSTACK;${PWD}"
    else
      BM_DIRECTORYSTACK="${PWD}"
    fi
    SEMICOUNT=${BM_DIRECTORYSTACK//[^;]/}
    echo ${#SEMICOUNT}: ${PWD}
  else
    echo "error: invalid option"
  fi
}

function vimclass {
  vim $(ack -l "\bclass $1\b")
}
