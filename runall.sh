#!/bin/bash

#PBS -N malha_db
#PBS -l select=1:ncpus=56
#PBS -l walltime=240:00:00
#PBS -q atlas

pg_ctl -D ~/BDs/db  start

cd /home/atlas/codigos/LTModel-pgsql

./luga_process.sh -j 56 > runAll.log 2>&1

pg_ctl -D ~/BDs/db  stop