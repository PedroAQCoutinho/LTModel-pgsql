curDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
start_date="$(date)"
SECONDS=0
procName=$4
echo Running: $procName
echo 
echo Started at: $start_date
echo 

. $curDir/bash_01_helpers.sh

userName=$1
databaseServer=$2 
databaseName=$3
SECONDS=0
set -e

psql -U $userName -h $databaseServer -d $databaseName -v var_num_proc=$5 -v var_proc=$i -f $4_1.sql

#If sql 2 exists execute it
if [ -f $4_2.sql ]; then
    for ((i=0; i < $5; i++))
    do
        psql -U $userName -h $databaseServer -d $databaseName -v var_num_proc=$5 -v var_proc=$i -f $4_2.sql &
        echo Finished proc $5
    done
    wait
fi


#If sql 3 exists execute it
if [ -f $4_3.sql ]; then
    psql -U $userName -h $databaseServer -d $databaseName -v var_num_proc=$5 -v var_proc=$i -f $4_3.sql
fi


echo Started at: 
echo $start_date
echo 
echo Finished at:
echo `date`
echo Elapsed:
displaytime $SECONDS