#!/bin/bash

#PBS -N db_malha
#PBS -l select=1:ncpus=56
#PBS -l walltime=240:00:00    
#PBS -q atlas

pg_ctl -D ~/BDs/db_malha  start

cd /home/atlas/codigos/LTModel-pgsql

#./luga_process.sh -j 56 -p 5432 > runAll_2020_break.log 2>&1
./bash_05_run_overlaying.sh -j 56 > runAll_2020_break_bash_05.log 2>&1

pg_ctl -D ~/BDs/db_malha  stop
