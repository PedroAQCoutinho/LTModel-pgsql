#!/bin/bash

#Parameters
curDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $curDir/bash_00_parseOptions.sh

#Run overlaying rules
function runOverlayingRules {
    psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "ALTER TABLE lt_model.lt_model_car_po_$varPriority RENAME TO lt_model_car_po;"
    psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "ALTER TABLE lt_model.lt_model_car_pr_$varPriority RENAME TO lt_model_car_pr;"
    psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -f run_stmt.sql
    . $curDir/bash_06_add_names2.sh -U $userName -h $databaseServer -d $databaseName -p $portNumber -v $varPriority
    psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "DROP TABLE IF EXISTS lt_model.result_$varPriority;ALTER TABLE lt_model.result RENAME TO result_$varPriority; ALTER INDEX lt_model.gix_result RENAME TO gix_result_$priority; CREATE TABLE lt_model.result AS SELECT * FROM lt_model.result_$priority WHERE false; CREATE INDEX gix_result ON lt_model.result USING GIST (geom);"
    psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "ALTER TABLE lt_model.lt_model_car_po RENAME TO lt_model_car_po_$varPriority;"
    psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "ALTER TABLE lt_model.lt_model_car_pr RENAME TO lt_model_car_pr_$varPriority;"
}


## Get run statement in sql file
psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -t -c "SELECT lt_model.run_statement()" > run_stmt.sql

## Run overlaying rules for random
runOverlayingRules "${@:$OPTIND+1:1}"

