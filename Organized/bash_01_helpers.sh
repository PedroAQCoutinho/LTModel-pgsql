curDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

userName=$1
databaseServer=$2 
databaseName=$3
numProc=$4
carTable=$5
wait=$6

if [ "$wait" == "" ]; then wait=false; fi

function waitAnyKey {
    read -n 1 -s -r -p "Press any key to continue $myArg"
}

function runProc {
  $curDir/bash_02_execproc.sh $userName $databaseServer $databaseName $1 $numProc $carTable
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

