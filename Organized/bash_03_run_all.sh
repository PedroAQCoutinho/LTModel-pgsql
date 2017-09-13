set -e

start_date="$(date)"
SECONDS=0
echo $start_date

curDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
userName=$1
databaseServer=$2 
databaseName=$3
numProc=$4
carTable=$5
wait=$6
specificProc=$7

#Import auxiliary functions
. $curDir/bash_01_helpers.sh $userName $databaseServer $databaseName $numProc $carTable $wait

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
    runProc proc1_01_makevalid
    runProc proc1_02_outsidebr
    runProc proc1_03_cleanequalshape
    runProc proc1_04_cleansamecar
    runProc proc1_05_car-sigef
    runProc proc1_06_car_sigef_union
    runProc proc1_07_car_autointersection
    runProc proc1_08_car_premium
    runProc proc1_09_car_intersects
    runProc proc1_10_car_poor_clean
    runProc proc1_11_car_premium_clean
    runProc proc1_12_car_poor-premium
    runProc proc1_13_car_poor_eliminate
}

if [ "$specificProc" == "" ]
    then 
        runAll
    else
        echo $specificProc
        runProc $specificProc
fi

finish