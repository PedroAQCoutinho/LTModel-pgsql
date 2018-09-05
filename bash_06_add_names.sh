curDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. $curDir/bash_00_parseOptions.sh

psql -p $portNumber -c "\copy (SELECT table_name, column_name FROM lt_model.inputs WHERE fla_proc AND column_name IS NOT NULL) TO 'saida.csv' WITH (FORMAT 'csv')"

OLDIFS=$IFS
IFS=,

while read tableName columnName
do
    psql -v var_table=$tableName -v var_column=$columnName -U $userName -h $databaseServer -d $databaseName -p $portNumber -f proc2_get_nome_result.sql
done < saida.csv

rm saida.csv
IFS=$OLDIFS
