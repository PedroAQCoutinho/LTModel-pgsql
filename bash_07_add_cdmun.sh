curDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $curDir/bash_00_parseOptions.sh

proc=(
  proc3_inserting_cdmun
)

for i in ${allProcs[@]}
  do 
    echo "runProc $i"
    runProc $i
  done