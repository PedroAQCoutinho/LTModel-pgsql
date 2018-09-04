curDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
start_date="$(date)"
SECONDS=0
. $curDir/bash_00_parseOptions.sh
. $curDir/bash_01_helpers.sh

procName=${@:$OPTIND:1}
echo Running: $procName
echo 
echo Started at: $start_date
echo 

SECONDS=0
set -e
psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -f ${procName}_1.sql

#If sql 2 exists execute it
if [ -f ${procName}_2.sql ]; then
    for ((i=0; i < ${numProc}; i++))
    do
        psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -v var_num_proc=$numProc -v var_proc=$i -f ${procName}_2.sql &
    done
    wait
fi


#If sql 3 exists execute it
if [ -f ${procName}_3.sql ]; then
    psql -U $userName -h $databaseServer -d $databaseName -p $portNumber -f ${procName}_3.sql
fi


echo Started at: 
echo $start_date
echo 
echo Finished at:
echo `date`
echo Elapsed:
displaytime $SECONDS
