#!/bin/bash
#set -x
prefix=$1
start=$2
end=$3
is_continue=
if [ -z "$prefix" ]; then
    prefix=192.168.205
fi
if [ -z "$start" ]; then
    start=1
fi
if [ -z "$end" ]; then
    end=255
fi
ping_cmd="ping -c 1 -W 2"
ping_cmd="arping -I enp0s25 -c 1 -w 1"
for i in `seq $start $end`; do
    ip=${prefix}.$i
    #ssh root@$ip "cat /root/.ssh/id_rsa.pub"
    if ! $ping_cmd $ip >/dev/null 2>&1 ;then
        if [ -z "$is_continue" ] ;then
            echo -n "$ip ... "
        fi
        is_continue=$ip
    else
        if [ -n "$is_continue" ] ;then
            echo $is_continue
        fi
        is_continue=
    fi
done
if [ -n $is_continue ] ;then
    echo $is_continue
    is_continue=
fi
