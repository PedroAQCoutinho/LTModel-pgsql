curDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $curDir/bash_00_parseOptions.sh
. $curDir/bash_01_helpers.sh

proc=(
  proc3_inserting_cdmun
)

echo proc_07_add_cdmun

for i in ${proc[@]}
  do 
    echo "runProc $i"
    runProc $i
  done