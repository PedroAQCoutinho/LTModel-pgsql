#!/bin/bash

#PBS -N malha_break
#PBS -l select=1:ncpus=56:nodetype=n56
#PBS -l walltime=120:00:00
#PBS -q atlas

#Altera o diretorio
cd /home/atlas/codigos/LTModel-pgsql/

#Carrega os modulos
module load gcc openmpi

#Da o start na base de dados
pg_ctl start -D ~/BDs/db_malha/

#Cria as bases de dados
psql -h 127.0.0.1 -U atlas -d atlas -p 5432 -a -f LTbreak_proc00-creating-tables.sql > LTbreak-log-output 2>&1

#Roda o processamento em paralelo
export OMP_NUM_THREADS=1
export NCPUS=$(qstat -fx $PBS_JOBID | grep "resources_used.ncpus" | tr -dc '0-9')
mpirun -np $NCPUS --hostfile $PBS_NODEFILE -x PATH -x LD_LIBRARY_PATH ./LTbreak-proc02-call-sql-scripts-euler.sh $NCPUS result_random_v201901 >> LTbreak-log-output 2>&1

#Consolida a tabela final
psql -h localhost -U atlas -d atlas -p 5432 -a -f LTbreak_proc05-unifying-final-dataset.sql >> LTbreak-log-output 2>&1

#Da o stop na base de dados
pg_ctl stop -D ~/BDs/db_malha/