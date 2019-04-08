#!/bin/bash

NCPUS=$1
LTENURE=$2

#Altera o diretorio
cd /home/atlas/codigos/LTModel-pgsql/

psql -h localhost -U atlas -d atlas -p 5432 -v var_proc=$OMPI_COMM_WORLD_RANK -v threads=$NCPUS -f LTbreak_proc01-breaking-mun-by-biome.sql &&
psql -h localhost -U atlas -d atlas -p 5432 -v var_proc=$OMPI_COMM_WORLD_RANK -v threads=$NCPUS -f LTbreak_proc02-breaking-mun-by-watershed.sql &&
psql -h localhost -U atlas -d atlas -p 5432 -v var_proc=$OMPI_COMM_WORLD_RANK -v threads=$NCPUS -v ltenure=$LTENURE -f LTbreak_proc03-identifying-unregistered-lands.sql &&
psql -h localhost -U atlas -d atlas -p 5432 -v var_proc=$OMPI_COMM_WORLD_RANK -v threads=$NCPUS -v ltenure=$LTENURE -f LTbreak_proc04-flagging-rural-properties.sql