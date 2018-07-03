#Parameters
userName=$1
databaseServer=$2 
databaseName=$3
numProc=$4
specificProc=$5
wait=$6
if [ "$wait" == "" ]; then wait=false; fi

function renameAppendCarTables {
    appendSuffix=$1
    psql -U $userName -h $databaseServer -d $databaseName -c "DROP TABLE IF EXISTS lt_model.proc1_12_car_cleaned_$appendSuffix;ALTER TABLE lt_model.proc1_12_car_cleaned RENAME TO proc1_12_car_cleaned_$appendSuffix;ALTER INDEX lt_model.gix_proc1_12_car_cleaned RENAME TO gix_proc1_12_car_cleaned_$appendSuffix;"
    #Create resulting lt_model_car_po and lt_model_car_pr tables
    psql -U $userName -h $databaseServer -d $databaseName -c "DROP TABLE IF EXISTS lt_model.lt_model_car_po_$appendSuffix;ALTER TABLE lt_model.lt_model_car_po RENAME TO lt_model_car_po_$appendSuffix; CREATE INDEX gix_lt_model_car_po_$appendSuffix ON lt_model.lt_model_car_po_$appendSuffix USING GIST (geom);"
    psql -U $userName -h $databaseServer -d $databaseName -c "DROP TABLE IF EXISTS lt_model.lt_model_car_pr_$appendSuffix; ALTER TABLE lt_model.lt_model_car_pr RENAME TO lt_model_car_pr_$appendSuffix; CREATE INDEX gix_lt_model_car_pr_$appendSuffix ON lt_model.lt_model_car_pr_$appendSuffix USING GIST (geom);"
}



#### PRIORITY RANDOM ####
#Set priority of CAR autointersection to Random ("R")
psql -U $userName -h $databaseServer -d $databaseName -c "UPDATE lt_model.params SET param_text = 'R' WHERE param_name = 'priority_autointersection'"
#Run INCRA and CAR consistency
./bash_03_run_all.sh $userName $databaseServer $databaseName $numProc $wait $specificProc
#Rename appending random to results
renameAppendCarTables "random"


#### PRIORITY SMALL ####
#Set priority of CAR autointersection to Small ("S")
psql -U $userName -h $databaseServer -d $databaseName -c "UPDATE lt_model.params SET param_text = 'S' WHERE param_name = 'priority_autointersection'"
#Run INCRA and CAR consistency
./bash_03_run_all.sh $userName $databaseServer $databaseName $numProc $wait proc1_10_car_poor_clean
#Rename proc1_12_car_cleaned to proc1_12_car_cleaned_small
renameAppendCarTables "small"


#### PRIORITY LARGE ####
#Set priority of CAR autointersection to Large ("L")
psql -U $userName -h $databaseServer -d $databaseName -c "UPDATE lt_model.params SET param_text = 'L' WHERE param_name = 'priority_autointersection'"
./bash_03_run_all.sh $userName $databaseServer $databaseName $numProc $wait proc1_10_car_poor_clean
#Rename proc1_12_car_cleaned to proc1_12_car_cleaned_large
renameAppendCarTables "small"


#Run overlaying rules
function runOverlayingRules {
    priority=$1
    psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.lt_model_car_po_$priority RENAME TO lt_model_car_po;"
    psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.lt_model_car_pr_$priority RENAME TO lt_model_car_pr;"
    psql -U $userName -h $databaseServer -d $databaseName -f run_stmt.sql
    psql -U $userName -h $databaseServer -d $databaseName -c "DROP TABLE IF EXISTS lt_model.result_$priority;ALTER TABLE lt_model.result RENAME TO result_$priority; ALTER INDEX lt_model.gix_result RENAME TO gix_result_$priority; CREATE TABLE lt_model.result AS SELECT * FROM lt_model.result_$priority WHERE false; CREATE INDEX gix_result ON lt_model.result USING GIST (geom);"
    psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.lt_model_car_po RENAME TO lt_model_car_po_$priority;"
    psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.lt_model_car_pr RENAME TO lt_model_car_pr_$priority;"
}


## Get run statement in sql file
psql -U $userName -h $databaseServer -d $databaseName -t -c "SELECT lt_model.run_statement()" > run_stmt.sql

## Run overlaying rules for random
runOverlayingRules "random"

## Run and log for small
runOverlayingRules "small"

## Run and log for large
runOverlayingRules "large"