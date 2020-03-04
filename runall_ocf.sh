#!/bin/bash

#PBS -N car_ocf
#PBS -l select=1:ncpus=56
#PBS -l walltime=240:00:00
#PBS -q atlas

pg_ctl -D ~/BDs/db_malha/  start

cd /home/atlas/codigos/LTModel-pgsql

./luga_process.sh -j 56 > runAll_ocf_carclean.log 2>&1

pg_ctl -D ~/BDs/db_malha/  stop