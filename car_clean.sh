#!/bin/bash

#PBS -N car_ocf
#PBS -l select=1:ncpus=56
#PBS -l walltime=240:00:00
#PBS -q atlas

pg_ctl -D ~/BDs/db_malha/  start

cd /home/atlas/codigos/LTModel-pgsql

psql < ocf_car_clean_proc00.sql

pg_ctl -D ~/BDs/db_malha/  stop