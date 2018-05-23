set -e

start_date="$(date)"
SECONDS=0
echo $start_date
echo

curDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
userName=$1
databaseServer=$2 
databaseName=$3
numProc=$4
carTable=$5
wait=$6
specificProc=$7
allProcs=(
    proc0_sigef_solve
    proc1_01_makevalid 
    proc1_02_outsidebr 
    proc1_03_cleanequalshape 
    proc1_04_cleansamecar 
    proc1_05_car-sigef 
    proc1_06_car_sigef_union 
    proc1_07_car_autointersection 
    proc1_08_car_premium 
    proc1_09_car_intersects 
    proc1_10_car_poor_clean 
    proc1_11_car_premium_clean 
    proc1_12_car_poor-premium 
    proc1_13_car_poor_eliminate
    proc2_01_junta_cdmun
    proc2_02_junta_cd_mun_not_within
    proc2_03_junta_cd_mun_intersection
    proc2_04_junta_cd_mun_final
    proc2_05_validate_all
    proc2_06_simulate
    proc2_07_simulate_single
    proc2_08_simulate_calculation
    proc2_09_clean_simulated_area
    proc2_10_calculation_continue
    proc2_11_voronoi
    proc2_12_insert_result2
)
found=false

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