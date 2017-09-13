curDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

userName=$1
databaseServer=$2 
databaseName=$3
SECONDS=0

set -e

psql -U $userName -h $databaseServer -d $databaseName -v car_table=$6 -v var_num_proc=$5 -v var_proc=$i -f $4_1.sql

#Exit if sql 2 not exists
if [ ! -f $4_2.sql ]; then
    exit
fi

for ((i=0; i < $5; i++))
do
    psql -U $userName -h $databaseServer -d $databaseName -v car_table=$6 -v var_num_proc=$5 -v var_proc=$i -f $4_2.sql &
done
wait


#Exit if sql 3 not exists
if [ ! -f $4_3.sql ]; then
    exit
fi

psql -U $userName -h $databaseServer -d $databaseName -v car_table=$6 -v var_num_proc=$5 -v var_proc=$i -f $4_3.sql