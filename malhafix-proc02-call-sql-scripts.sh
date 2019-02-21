#!/bin/bash

NCPUS=$1
LTENURE=$2
LTENURE_CDMUN=$3

cd /home/atlas/codigos/LTModel-pgsql/

psql -h 127.0.0.1 -U atlas -d atlas -v var_proc=$OMPI_COMM_WORLD_RANK -v threads=$NCPUS -v ltenure=$LTENURE -v ltenure_cdmun=$LTENURE_CDMUN -a -f malhafix_inserting-cdmun.sql &&
psql -h 127.0.0.1 -U atlas -d atlas -v ltenure=$LTENURE -v ltenure_cdmun=$LTENURE_CDMUN -a -f malhafix_inserting-cdmun-to-result.sql 