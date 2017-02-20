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
    scp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-CR.repo /etc/yum.repos.d/CentOS-Debuginfo.repo /etc/yum.repos.d/CentOS-fasttrack.repo /etc/yum.repos.d/CentOS-Sources.repo /etc/yum.repos.d/CentOS-Vault.repo $host:/etc/yum.repos.d/
    ssh $host "if ! grep '^nameserver' /etc/resolv.conf ;then echo 'nameserver 114.114.114.114' >> /etc/resolv.conf ; systemctl restart network; fi"
    ssh $host "yum clean all"
    try ssh $host "yum install -y epel-release"
    #ssh $host "yum install -y python-pymongo"
    #ssh $host "yum install -y epel-release"
    try ssh $host "yum install -y python-pip"
    try ssh $host "pip install pymongo"
    ssh $host "unzip agent.zip"
    try ssh $host "cd instance_monitor_agent.git; python setup.py install"
    #ssh $host '\cp -f instance_monitor_agent.git/etc/VMAgent.conf /etc/VMAgent/VMAgent.conf'
    ssh $host 'sed -i '\'"s/^server_host.*/server_host = \"${server_ip}\"/g"\'' /etc/VMAgent/VMAgent.conf'
    ssh $host 'sed -i '\'"s/^mongodb_host.*/mongodb_host = \"${mongo_ip}\"/g"\'' /etc/VMAgent/VMAgent.conf'
    ssh $host "VMAgent-stop"
    ssh $host "VMAgent > /dev/null"
    if [ $? -eq 0 ]; then
        ret=success
    else
        ret=failed
    fi
    echo $host:$ret >> result.log
done
