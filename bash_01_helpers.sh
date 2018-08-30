curDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ "$wait" == "" ]; then wait=false; fi

function waitAnyKey {
    read -n 1 -s -r -p "Press any key to continue $myArg"
}

function runProc {
  $curDir/bash_02_execproc.sh -U $userName -h $databaseServer -d $databaseName -p $portNumber -j $numProc $1
  if $wait; then waitAnyKey; fi
}

function displaytime {
  local T=$1
  local D=$((T/60/60/24))
  local H=$((T/60/60%24))
  local M=$((T/60%60))
  local S=$((T%60))
  (( $D > 0 )) && printf '%d days ' $D
  (( $H > 0 )) && printf '%d hours ' $H
  (( $M > 0 )) && printf '%d minutes ' $M
  (( $D > 0 || $H > 0 || $M > 0 )) && printf 'and '
  printf '%d seconds\n' $S
}

