#!/bin/bash
IP=$1
device=`ifconfig | grep -B 2 $IP | grep -v $IP | awk '{print $1}'`
echo $device


