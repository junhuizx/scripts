#!/bin/bash
set -x
if [[ $# < 2 ]]; then
    echo usage: $0 [server ip] [mongodb ip]
    exit 1
fi
server_ip=$1
mongo_ip=$2
touch result.log
function try()
{
    T=3
    echo try "$*" command $T times
    for i in `seq 1 $T` ; do
        if $* ; then
            break
        fi
        echo $i failed
    done
}
source keystonerc_admin
mkdir vmagent; cd vmagent
curl https://git.newtouch.com/user6358/instance_monitor_agent/repository/archive.zip -o agent.zip
for host in `nova service-list --binary nova-compute  | awk -F\| '{if($2~"[0-9]+")print $4}'`; do
    echo ===================
    echo $host
    echo ===================
    openstack hypervisor show $host -c host_ip | grep host_ip | awk '{print $4}'
    ssh $host "rm -rf instance_monitor_agent.git agent.zip"
    scp agent.zip $host:~/
    try ssh $host "cd instance_monitor_agent.git; python setup.py install"
    ssh $host "VMAgent-stop"
    ssh $host "VMAgent > /dev/null"
    if [ $? -eq 0 ]; then
        ret=success
    else
        ret=failed
    fi
    echo $host:$ret >> result.log
done
