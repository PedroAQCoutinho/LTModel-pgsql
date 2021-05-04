#!/bin/bash

#Parameters
curDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $curDir/bash_00_parseOptions.sh

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
./bash_03_run_all.sh -U $userName -h $databaseServer -d $databaseName -p $portNumber -j $numProc $useWait $specificProc
#Rename appending random to results
renameAppendCarTables "random"


#### PRIORITY SMALL ####
#Set priority of CAR autointersection to Small ("S")
  #psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "UPDATE lt_model.params SET param_text = 'S' WHERE param_name = 'priority_autointersection'"
#Run INCRA and CAR consistency
  #./bash_03_run_all.sh -U $userName -h $databaseServer -d $databaseName -p $portNumber -j $numProc $useWait proc1_10_car_poor_clean
#Rename proc1_12_car_cleaned to proc1_12_car_cleaned_small
  #renameAppendCarTables "small"


#### PRIORITY LARGE ####
#Set priority of CAR autointersection to Large ("L")
  #psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "UPDATE lt_model.params SET param_text = 'L' WHERE param_name = 'priority_autointersection'"
#Run INCRA and CAR consistency
  #./bash_03_run_all.sh -U $userName -h $databaseServer -d $databaseName -p $portNumber -j $numProc $useWait proc1_10_car_poor_clean
#Rename proc1_12_car_cleaned to proc1_12_car_cleaned_large
  #renameAppendCarTables "large"


#Run overlaying rules
. $curDir/bash_05_run_overlaying.sh -U $userName -h $databaseServer -d $databaseName -j $numProc -v random $useWait 

#. $curDir/bash_05_run_overlaying.sh -U $userName -h $databaseServer -d $databaseName -j $numProc -v small $useWait 

#. $curDir/bash_05_run_overlaying.sh -U $userName -h $databaseServer -d $databaseName -j $numProc -v large $useWait 

#Adding cdmun to result
