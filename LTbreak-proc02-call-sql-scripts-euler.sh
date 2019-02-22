#!/bin/bash

NCPUS=$1
LTENURE=$2

#Altera o diretorio
cd /home/atlas/codigos/LTModel-pgsql/

psql -h localhost -U atlas -d atlas -p 5434 -v var_proc=$OMPI_COMM_WORLD_RANK -v threads=$NCPUS -v ltenure=$LTENURE -f LTbreak_proc01-identifying-unregistered-lands.sql &&
psql -h localhost -U atlas -d atlas -p 5434 -v ltenure=$LTENURE -f LTbreak_proc02-unifying-landtenure-map.sql &&
psql -h localhost -U atlas -d atlas -p 5434 -v var_proc=$OMPI_COMM_WORLD_RANK -v threads=$NCPUS -f LTbreak_proc03-breaking-by-municipality.sql &&
psql -h localhost -U atlas -d atlas -p 5434 -v var_proc=$OMPI_COMM_WORLD_RANK -v threads=$NCPUS -f LTbreak_proc04-breaking-by-biome.sql &&
psql -h localhost -U atlas -d atlas -p 5434 -v var_proc=$OMPI_COMM_WORLD_RANK -v threads=$NCPUS -f LTbreak_proc05-breaking-by-watershed.sql
