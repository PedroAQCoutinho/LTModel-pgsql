#!/bin/bash

#PBS -N malha_db
#PBS -l select=1:ncpus=56
#PBS -l walltime=240:00:00
#PBS -q atlas

#Muda o diretório para o diretório do exemplo
pg_ctl -D ~/BDs/db  start
# sleep 5
cd /home/atlas/codigos/LTModel-pgsql

#Não se esqueça de conferir o conteúdo do arquivo script.R
./luga_process.sh -j 56 > runAll_2019.log 2>&1
pg_ctl -D ~/BDs/db  stop
