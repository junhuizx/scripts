#!/bin/bash
#set -x
if [[ $1 == '-e' ]];then
    find_empty=1
    shift
fi
prefix=$1
start=$2
end=$3
is_continue=
if [ -z "$prefix" ]; then
    prefix=192.168.1
fi
if [ -z "$start" ]; then
    start=1
fi
if [ -z "$end" ]; then
    end=255
fi
myself=
device=
function myarping(){
    ip=${!#}
    echo $ip $device
    [[ a$ip == a$myself ]] || arping -I $device -c 1 -w 1 $*
}
ping_cmd="ping -c 1 -W 2"
device=`ip a | grep $prefix -B2 | awk -F: '{if($1 ~ "^[0-9]+$")print $2}'`
if [[ -n $device ]]; then
    myself=`ip a | grep 172.16.0 | awk '{print $2}' | awk -F/ '{print $1}'`
    ping_cmd="arping -I $device -c 1 -w 1"
    ping_cmd="myarping"
fi
for i in `seq $start $end`; do
    ip=${prefix}.$i
    #ssh root@$ip "cat /root/.ssh/id_rsa.pub"
    $ping_cmd $ip >/dev/null 2>&1 
    ret=$?
    if  ( [[ -n $find_empty ]] && [[ $ret != 0 ]] ) || ( [[ -z $find_empty ]] && [[ $ret == 0 ]] );then
        if [ -z "$is_continue" ] ;then
            echo -n "$ip"
        fi
        is_continue=$ip
    else
        if [[ -n "$is_continue" ]] ;then
            echo " ... $is_continue"
        fi
        is_continue=
    fi
done
if [[ -n $is_continue ]] ;then
    echo " ... $is_continue"
    is_continue=
fi
