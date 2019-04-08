#!/bin/bash

#PBS -N malha_cd_mun
#PBS -l select=1:ncpus=40:nodetype=n40
#PBS -l walltime=120:00:00
#PBS -q atlas


#Parametro que indica a versão da malha fundiária
#                     --------------- IMPORTANTE -------------------
#EX: qsub malhafix-proc01-submit-to-euler.sh -v ltenure=result_random_v201901



cdmun=_cdmun
ltenure_cdmun=$ltenure$cdmun

#Altera o diretorio
cd /home/atlas/codigos/LTModel-pgsql/

#Carrega os modulos
module load gcc openmpi

#Da o start na base de dados
pg_ctl start -D ~/BDs/db/
#pg_ctl start -D ~/BDs/database2/

#Cria as bases de dados
psql -h 127.0.0.1 -U atlas -d atlas -a -v ltenure_cdmun=$ltenure_cdmun -f malhafix_inserting-cdmun-create-table.sql

#Roda o processamento em paralelo

export OMP_NUM_THREADS=1
export NCPUS=$(qstat -fx $PBS_JOBID | grep "resources_used.ncpus" | tr -dc '0-9')
mpirun -np $NCPUS --hostfile $PBS_NODEFILE -x PATH -x LD_LIBRARY_PATH ./malhafix-proc02-call-sql-scripts.sh $NCPUS $ltenure $ltenure_cdmun >> log-malhafix-main 2>&1

#Da o stop na base de dados
pg_ctl stop -D ~/BDs/db/
#pg_ctl stop -D ~/BDs/database2/