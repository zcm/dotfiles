# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

# Source the local rc, if it exists
if [ -f ~/.local_bashrc ]; then
  . ~/.local_bashrc
fi

export PATH=$PATH:~/.local/bin
export PS1="\[$(tput bold)\][\[$(tput setaf 2)\]\u\[$(tput setaf 0)\]@\[$(tput setaf 5)\]\h\[$(tput setaf 7)\] \W\[$(tput sgr0)\]\[$(tput bold)\]]\\$ \[$(tput sgr0)\]"

# User specific aliases and functions

function authorize_ssh {
  local SHOW_USAGE=0

  local AUTHUSER=
  local TARGETUSER=$AUTHUSER

  if [ "$#" == "0" -o "$#" == "1" ]; then
    printf "error: not enough arguments\n\n"
    SHOW_USAGE=1
  else
    AUTHUSER=$1
    local PUBLICKEY=~/.ssh/id_rsa.pub
    local AUTHKEYS='.ssh/authorized_keys'
    shift

    if [ "$1" == "::" ]; then
      if [ "$#" -lt "3" ]; then
        echo "error: not enough arguments"
        echo "       (did you specify hosts after :: username2?)"
        echo ""
        SHOW_USAGE=1
      else
        shift
        TARGETUSER=$1
        shift
      fi
    fi
  fi

  if [ "$SHOW_USAGE" -ne "0" ]; then
    echo "usage: authorize_ssh username host1 [host2... hostN]"
    echo "         Simple mode: Authorize the current user to login as username"
    echo "         on the hosts."
    echo ""
    echo "       authorize_ssh username1 :: username2 host1 [host2... hostN]"
    echo "         Advanced mode: First log in to the hosts as username1, then"
    echo "         authorize the current user to login as username2. Useful for"
    echo "         when you need to first use another user (i.e. root) to get"
    echo "         access to the user you want to authorize."
    echo ""
    return 1
  fi

  local SUDOCMD=
  if [ "$AUTHUSER" != "$TARGETUSER" ]; then
    SUDOCMD="sudo -u $TARGETUSER"
  fi

  if [ -f "$PUBLICKEY" ]; then
    local KEYVALUE=`cat $PUBLICKEY`

    echo "Password for $AUTHUSER. Leave blank to prompt for each host."
    stty -echo
    local REMOTE_PW=
    read -p "Remote password: " REMOTE_PW; echo
    stty echo

    local SSHPASS_CMD=
    if [ "$REMOTE_PW" != "" ]; then
      SSHPASS_CMD="sshpass -p $REMOTE_PW"
    fi

    while (( "$#" )); do
      if [ "$AUTHUSER" != "$TARGETUSER" ]; then
        echo "Authorizing user $TARGETUSER on host $1 via user $AUTHUSER..."
      else
        printf "Authorizing user %s on host %s...\n" "$AUTHUSER" "$1"
      fi
      local TARGET=/home/$TARGETUSER/$AUTHKEYS
      $SSHPASS_CMD ssh $AUTHUSER@$1 "$SUDOCMD echo \"$KEYVALUE\" >> $TARGET"
      if [ $? -ne 0 ]; then
        printf "Failed.\n"
      else
        printf "Successfully authorized.\n"
      fi
      shift
    done
  else
    echo "error: you must have a public key at $PUBLICKEY to authorize"
    return 1
  fi
}

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
  local FOUND_FILE=$(global -a $1 | xargs)
  echo $FOUND_FILE
  if [[ "$FOUND_FILE" == "" ]]; then
    FOUND_FILE=$(ack -l "\bclass $1\b" --ignore-file=ext:html,xml)
  fi
  if [[ "$FOUND_FILE" == "" ]]; then
    echo "vimclass: error: cannot locate class '$1'"
  else
    vim $FOUND_FILE
  fi
}

function _complete_code_token {
  cur=${COMP_WORDS[COMP_CWORD]}
  pattern="^$cur.*"
  COMPREPLY=( $( compgen -W "$(global -x $pattern | sed -E -e 's/\s.*$//g')" -- $cur ) )
}

complete -o nospace -F _complete_code_token vimclass

function vimack {
  vim $(ack -l $@)
}

function jumpto {
  cd `global -a $@ | sed 's,/*[^/]\+/*$,,'`
}

complete -o nospace -F _complete_code_token jumpto
