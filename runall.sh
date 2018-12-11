#!/bin/bash

#PBS -N luga_ima_caio
#PBS -l select=1:ncpus=56
#PBS -l walltime=240:00:00
#PBS -q atlas

#Muda o diretório para o diretório do exemplo
pg_ctl start
# sleep 5
cd /home/atlas/codigos/LTModel-pgsql

#Não se esqueça de conferir o conteúdo do arquivo script.R
./luga_process.sh -j 56 proc1_08_car_premium > runAll.log 2>&1
pg_ctl stop
