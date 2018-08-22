#!/bin/bash

#Parameters
curDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
userName=postgres
databaseServer=127.0.0.1
databaseName=atlas
numProc=1
portNumber=5432
wait=false

while getopts "U:p:h:d:j:w" opt; do
  case $opt in
    h) databaseServer=$OPTARG;;
    U) userName=$OPTARG;;
    p) portNumber=$OPTARG;;
    d) databaseName=$OPTARG;;
    j) numProc=$OPTARG;;
    w) wait=true;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

specificProc=${@:$OPTIND:1}

set -e
start_date="$(date)"
SECONDS=0
echo $start_date
echo

curDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
allProcs=(
    proc0_sigef_solve
    proc1_01_makevalid
    proc1_02_outsidebr
    proc1_03_cleanequalshape
    proc1_04_cleansamecar
    proc1_07_car_autointersection
    proc1_08_car_premium
    proc1_09_car_intersects
    proc1_10_car_poor_clean
    proc1_11_car_premium_clean
    proc1_12_car_poor-premium
    proc1_13_car_poor_eliminate
    proc1_14_car-sigef
    proc1_15_car_sigef_remove
)
found=false

#Import auxiliary functions
. $curDir/bash_01_helpers.sh $userName $databaseServer $databaseName $numProc $wait

function finish {
    echo Started:
    echo $start_date
    echo 
    echo Finished:
    date
    echo Total elapsed time:
    displaytime $SECONDS
    exit
}

function runAll {
    for i in ${allProcs[@]}
        do runProc $i
    done
}

if [ "$specificProc" == "" ]
    then 
        echo "Didn't specified proc, running from beginning!"
        runAll
    else
        echo Started from proc: $specificProc
        for i in ${allProcs[@]}
        do 
            if [ "$i" == "$specificProc" ] || [ "$found" == "true" ]; then
                found=true
                runProc $i
            else : 
            fi; 
        done;
fi

finish
