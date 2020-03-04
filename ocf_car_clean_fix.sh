#!/bin/bash

#PBS -N db_malha
#PBS -l select=1:ncpus=56
#PBS -l walltime=300:00:00
#PBS -q atlas

cd /home/atlas/codigos/LTModel-pgsql

pg_ctl -D ~/BDs/db_malha/ start

./bash_05_run_overlaying.sh -h 127.0.0.1 -U atlas -p 5432 -d atlas -j 56 -v random > ocf_car_fix.log 2>&1

pg_ctl -D ~/BDs/db_malha/ stop