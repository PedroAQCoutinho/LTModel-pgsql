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
