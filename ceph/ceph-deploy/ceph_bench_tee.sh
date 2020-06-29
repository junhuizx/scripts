#!/bin/bash
set -x
echo rados -b 4194304 -o 4194304  bench -p testbench 120 write  -t 12  --no-cleanup | tee bench.out
rados -b 4194304 -o 4194304  bench -p testbench 120 write  -t 12  --no-cleanup | tee bench.out
echo -e "\n\n\n" >> bench.out

echo rados -b 4096 -o 4194304  bench -p testbench 120 write  -t 12  --no-cleanup |tee -a bench.out
rados -b 4096 -o 4194304  bench -p testbench 120 write  -t 12  --no-cleanup |tee -a bench.out
echo -e "\n\n\n" >> bench.out


echo rados bench -p testbench 120 seq  -t 12  --no-cleanup |tee -a bench.out
rados bench -p testbench 120 seq  -t 12  --no-cleanup | tee -a bench.out
echo -e "\n\n\n" >> bench.out

echo rados bench -p testbench 120 rand  -t 12  --no-cleanup | tee -a bench.out
rados bench -p testbench 120 rand  -t 12  --no-cleanup | tee -a bench.out
echo -e "\n\n\n" >> bench.out


echo rados  -p testbench cleanup

