#!/bin/bash
set -x
if [[ $# -le 4 ]]; then
    echo usage $0 [prefix] [start] [end] [user] [command]..
    exit 1
fi
prefix=$1
start=$2
end=$3
user=$4
shift 4
echo $*
for i in `seq $start $end`; do
    ip=$prefix.$i
    echo $ip
    ssh $user@$ip "$*"
done
