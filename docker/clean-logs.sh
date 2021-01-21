#!/bin/bash
if [ $# -eq 1 ]; then
  id=`docker inspect $1 | grep \"Id\" | awk -F\" '{print $4}'`
  find_name="$id-json.log*"
else
  find_name="*-json.log*"
fi
logs=$(find /var/lib/docker/containers/ -name "$find_name")

for log in $logs; do
  echo "clean logs : $log"
  cat /dev/null > $log
done
