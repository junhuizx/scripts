#!/bin/bash
#set -x
if [[ $1 -eq  "-h" ]];then
  echo usage: $0 disk partnum partsize [create remain size]
  exit 1
fi
disk=$1
partnum=$2
partsize=$3

fdisk_script=./fdisk_script_`basename $disk`

echo -en "g\n" > $fdisk_script
for i in `seq 1 $partnum`; do
  echo -en "n\n$i\n\n+$partsize\n" >> $fdisk_script
done
if [[ -n $4 ]]; then
  i=$((i+1))
  echo -en "n\n$i\n\n\n" >> $fdisk_script
fi
echo -en "w\n\nq\n" >> $fdisk_script
cat $fdisk_script | fdisk $disk

