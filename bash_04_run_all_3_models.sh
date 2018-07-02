#Parameters
userName=$1
databaseServer=$2 
databaseName=$3
numProc=$4
carTable=$5
wait=$6
specificProc=$7



#### PRIORITY RANDOM ####
#Set priority of CAR autointersection to Random ("R")
psql -U $userName -h $databaseServer -d $databaseName -c "UPDATE lt_model.params SET param_text = 'R' WHERE param_name = 'priority_autointersection'"

#Run INCRA and CAR consistency
./bash_03_run_all.sh $1 $2 $3 $4 $5 $6 $7


#Rename proc1_12_car_cleaned to proc1_12_car_cleaned_random
psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.proc1_12_car_cleaned RENAME TO proc1_12_car_cleaned_random"
#Create resulting lt_model_car_po and lt_model_car_pr tables
psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.lt_model_car_po RENAME TO lt_model_car_po_random"
psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.lt_model_car_pr RENAME TO lt_model_car_pr_random"


#### PRIORITY SMALL ####
#Set priority of CAR autointersection to Small ("S")
psql -U $userName -h $databaseServer -d $databaseName -c "UPDATE lt_model.params SET param_text = 'S' WHERE param_name = 'priority_autointersection'"
./bash_03_run_all.sh $1 $2 $3 $4 $5 $6 proc1_10_car_poor_clean

#Rename proc1_12_car_cleaned to proc1_12_car_cleaned_small
psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.proc1_12_car_cleaned RENAME TO proc1_12_car_cleaned_small"
#Create resulting lt_model_car_po and lt_model_car_pr tables
psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.lt_model_car_po RENAME TO lt_model_car_po_small"
psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.lt_model_car_pr RENAME TO lt_model_car_pr_small"


#### PRIORITY LARGE ####
#Set priority of CAR autointersection to Large ("L")
psql -U $userName -h $databaseServer -d $databaseName -c "UPDATE lt_model.params SET param_text = 'L' WHERE param_name = 'priority_autointersection'"
./bash_03_run_all.sh $1 $2 $3 $4 $5 $6 proc1_10_car_poor_clean

#Rename proc1_12_car_cleaned to proc1_12_car_cleaned_large
psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.proc1_12_car_cleaned RENAME TO proc1_12_car_cleaned_large"
#Create resulting lt_model_car_po and lt_model_car_pr tables
psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.lt_model_car_po RENAME TO lt_model_car_po_large"
psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.lt_model_car_pr RENAME TO lt_model_car_pr_large"


#Run overlaying rules

## Get run statement in sql file
psql -U $userName -h $databaseServer -d $databaseName -c "SELECT lt_model.run_statement()" > run_stmt.sql

## Run overlaying rules for random
priority=random
psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.lt_model_car_po_$priority RENAME TO lt_model_car_po;"
psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.lt_model_car_pr_$priority RENAME TO lt_model_car_pr;"
psql -U $userName -h $databaseServer -d $databaseName -f run_stmt.sql
psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.result RENAME TO result_$priority; ALTER INDEX lt_model.gix_result RENAME TO gix_result_$priority; CREATE TABLE lt_model.result AS SELECT * FROM lt_model.result_$priority WHERE false; CREATE INDEX gix_result ON lt_model.result USING GIST (geom);"
psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.lt_model_car_po RENAME TO lt_model_car_po_$priority;"
psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.lt_model_car_pr RENAME TO lt_model_car_pr_$priority;"

## Run and log for small
priority=small
psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.lt_model_car_po_$priority RENAME TO lt_model_car_po;"
psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.lt_model_car_pr_$priority RENAME TO lt_model_car_pr;"
psql -U $userName -h $databaseServer -d $databaseName -f run_stmt.sql
psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.result RENAME TO result_$priority; ALTER INDEX lt_model.gix_result RENAME TO gix_result_$priority; CREATE TABLE lt_model.result AS SELECT * FROM lt_model.result_$priority WHERE false; CREATE INDEX gix_result ON lt_model.result USING GIST (geom);"
psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.lt_model_car_po RENAME TO lt_model_car_po_$priority;"
psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.lt_model_car_pr RENAME TO lt_model_car_pr_$priority;"


## Run and log for large
priority=large
psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.lt_model_car_po_$priority RENAME TO lt_model_car_po;"
psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.lt_model_car_pr_$priority RENAME TO lt_model_car_pr;"
psql -U $userName -h $databaseServer -d $databaseName -f run_stmt.sql
psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.result RENAME TO result_$priority; ALTER INDEX lt_model.gix_result RENAME TO gix_result_$priority; CREATE TABLE lt_model.result AS SELECT * FROM lt_model.result_$priority WHERE false; CREATE INDEX gix_result ON lt_model.result USING GIST (geom);"
psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.lt_model_car_po RENAME TO lt_model_car_po_$priority;"
psql -U $userName -h $databaseServer -d $databaseName -c "ALTER TABLE lt_model.lt_model_car_pr RENAME TO lt_model_car_pr_$priority;"