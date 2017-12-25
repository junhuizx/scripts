#!/bin/bash
set -x
base=`dirname $0`
base=`cd $base;pwd`
cd -

if [[ $# < 1 ]]; then
    echo $0 [password]
    exit 1
fi
if [[ ! -f /usr/bin/expect ]]; then
	if which yum; then
		sudo yum install -y expect
	elif which apt ; then
		sudo apt install -y expect
	fi
fi

password=$1

function find_host()
{
    hosts=(`cat /etc/hosts  | awk '{print $2}'| sort 2>/dev/null`)
    num=${#hosts[@]}

    for ((i=0;i<$num;i++))
    do
        echo ${hosts[$i]}
    done
}

$base/ssh-keygen.expect
for host in `find_host`; do
    $base/ssh-copy-id.expect "$host" "$password"
done



