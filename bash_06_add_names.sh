curDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $curDir/bash_00_parseOptions.sh

psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "\copy (SELECT table_name, column_name FROM lt_model.inputs WHERE fla_proc AND column_name IS NOT NULL) TO 'saida.csv' WITH (FORMAT 'csv')"

OLDIFS=$IFS
IFS=,

underline=_

echo proc_06_add_names
echo $varPriority
carType=po
psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "TRUNCATE lt_model.lt_model_car_sim_$carType;INSERT INTO lt_model.lt_model_car_sim_$carType SELECT gid, gid gid2, area, area_loss, area_original, cod_imovel, is_premium, geom FROM lt_model.lt_model_car_${carType}";
carType=pr
psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -c "TRUNCATE lt_model.lt_model_car_sim_$carType;INSERT INTO lt_model.lt_model_car_sim_$carType SELECT gid, gid gid2, area, area_loss, area_original, cod_imovel, is_premium, geom FROM lt_model.lt_model_car_${carType}";


while read tableName columnName
do
    psql -v var_table=$tableName -v var_column=$columnName -U $userName -h $databaseServer -d $databaseName -p $portNumber -f proc2_get_name_result.sql
done < saida.csv


rm saida.csv
IFS=$OLDIFS
