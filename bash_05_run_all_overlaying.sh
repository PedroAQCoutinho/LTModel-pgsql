#!/bin/bash

#Parameters
curDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $curDir/bash_00_parseOptions.sh

#Run overlaying rules
function runOverlayingRules {
    priority=$1
    psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "ALTER TABLE lt_model.lt_model_car_po_$priority RENAME TO lt_model_car_po;"
    psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "ALTER TABLE lt_model.lt_model_car_pr_$priority RENAME TO lt_model_car_pr;"
    psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -f run_stmt.sql
    psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "DROP TABLE IF EXISTS lt_model.result_$priority;ALTER TABLE lt_model.result RENAME TO result_$priority; ALTER INDEX lt_model.gix_result RENAME TO gix_result_$priority; CREATE TABLE lt_model.result AS SELECT * FROM lt_model.result_$priority WHERE false; CREATE INDEX gix_result ON lt_model.result USING GIST (geom);"
    psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "ALTER TABLE lt_model.lt_model_car_po RENAME TO lt_model_car_po_$priority;"
    psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "ALTER TABLE lt_model.lt_model_car_pr RENAME TO lt_model_car_pr_$priority;"
}


## Get run statement in sql file
psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -t -c "SELECT lt_model.run_statement()" > run_stmt.sql

## Run overlaying rules for random
runOverlayingRules "random"

## Run and log for small
runOverlayingRules "small"

## Run and log for large
runOverlayingRules "large"
