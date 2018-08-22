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


function renameAppendCarTables {
    appendSuffix=$1
    psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "DROP TABLE IF EXISTS lt_model.proc1_12_car_cleaned_$appendSuffix;ALTER TABLE lt_model.proc1_12_car_cleaned RENAME TO proc1_12_car_cleaned_$appendSuffix;ALTER INDEX lt_model.gix_proc1_12_car_cleaned RENAME TO gix_proc1_12_car_cleaned_$appendSuffix;"
    #Create resulting lt_model_car_po and lt_model_car_pr tables
    psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "DROP TABLE IF EXISTS lt_model.lt_model_car_po_$appendSuffix;ALTER TABLE lt_model.lt_model_car_po RENAME TO lt_model_car_po_$appendSuffix; CREATE INDEX gix_lt_model_car_po_$appendSuffix ON lt_model.lt_model_car_po_$appendSuffix USING GIST (geom);"
    psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "DROP TABLE IF EXISTS lt_model.lt_model_car_pr_$appendSuffix; ALTER TABLE lt_model.lt_model_car_pr RENAME TO lt_model_car_pr_$appendSuffix; CREATE INDEX gix_lt_model_car_pr_$appendSuffix ON lt_model.lt_model_car_pr_$appendSuffix USING GIST (geom);"
}



#### PRIORITY RANDOM ####
#Set priority of CAR autointersection to Random ("R")
psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "UPDATE lt_model.params SET param_text = 'R' WHERE param_name = 'priority_autointersection'"
#Run INCRA and CAR consistency
./bash_03_run_all.sh -U $userName -h $databaseServer -d $databaseName -p $portNumber -j $numProc -w $wait $specificProc
#Rename appending random to results
renameAppendCarTables "random"


#### PRIORITY SMALL ####
#Set priority of CAR autointersection to Small ("S")
psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "UPDATE lt_model.params SET param_text = 'S' WHERE param_name = 'priority_autointersection'"
#Run INCRA and CAR consistency
./bash_03_run_all.sh -U $userName -h $databaseServer -d $databaseName -p $portNumber -j $numProc -w $wait proc1_10_car_poor_clean
#Rename proc1_12_car_cleaned to proc1_12_car_cleaned_small
renameAppendCarTables "small"


#### PRIORITY LARGE ####
#Set priority of CAR autointersection to Large ("L")
psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "UPDATE lt_model.params SET param_text = 'L' WHERE param_name = 'priority_autointersection'"
./bash_03_run_all.sh -U $userName -h $databaseServer -d $databaseName -p $portNumber -j $numProc -w $wait proc1_10_car_poor_clean
#Rename proc1_12_car_cleaned to proc1_12_car_cleaned_large
renameAppendCarTables "small"


#Run overlaying rules
. $curDir/bash_05_run_all_overlaying.sh $userName $databaseServer $databaseName $numProc $wait
