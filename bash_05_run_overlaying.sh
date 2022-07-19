#!/bin/bash

#Parameters
curDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $curDir/bash_00_parseOptions.sh

echo proc_05_run_overlaying
echo $varPriority
#Run overlaying rules
function runOverlayingRules {
    psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "ALTER TABLE recorte.lt_model_car_po_$varPriority RENAME TO lt_model_car_po;"
    psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "ALTER TABLE recorte.lt_model_car_pr_$varPriority RENAME TO lt_model_car_pr;"
    psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -f run_stmt.sql
    . $curDir/bash_06_add_names.sh -U $userName -h $databaseServer -d $databaseName -p $portNumber -v $varPriority
    . $curDir/bash_07_add_cdmun.sh -U $userName -h $databaseServer -d $databaseName -j $numProc
    psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "DROP TABLE IF EXISTS recorte.result_$varPriority;ALTER TABLE recorte.result RENAME TO result_$varPriority; ALTER INDEX recorte.gix_result RENAME TO gix_result_$varPriority; CREATE TABLE recorte.result AS SELECT * FROM recorte.result_$varPriority WHERE false; CREATE INDEX gix_result ON recorte.result USING GIST (geom);"
    psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "ALTER TABLE recorte.lt_model_car_po RENAME TO lt_model_car_po_$varPriority;"
    psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "ALTER TABLE recorte.lt_model_car_pr RENAME TO lt_model_car_pr_$varPriority;"
}


## Get run statement in sql file
psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -t -c "SELECT recorte.run_statement()" > run_stmt.sql

## Run overlaying rules for random
runOverlayingRules