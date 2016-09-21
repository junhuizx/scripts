#!/bin/bash
set -x
kill_list_cmd='ps -ef | grep "'$1'" | grep -v grep | grep -v '"$0"
kill_list_cmd_post=' | awk '\''{print $2}'\'

echo ${kill_list_cmd}
kill_list=`eval ${kill_list_cmd} ${kill_list_cmd_post}`
kill $kill_list
for each in $kill_list
do
    if ps --pid $each; then
         kill -9 $each
    fi
done

