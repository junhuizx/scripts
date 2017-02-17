#!/bin/bash

server_ip=$1
mongo_ip=$2
source keystonerc_admin
mkdir vmagent; cd vmagent
curl https://git.newtouch.com/user6358/instance_monitor_agent/repository/archive.zip -o agent.zip
for host in `nova service-list --binary nova-compute  | awk -F\| '{if($2~"[0-9]+")print $4}'`; do
    echo $host
    openstack hypervisor show $host -c host_ip | grep host_ip | awk '{print $4}'
	ssh $host "rm -rf instance_monitor_agent.git agent.zip"
	scp agent.zip $host:~/
	scp /etc/yum.repos.d/CentOS* $host:/etc/yum.repos.d/
	ssh $host "if ! grep nameserver /etc/resolv.conf ;then echo 'nameserver 114.114.114.114' >> /etc/resolv.conf ; systemctl restart network; fi"
	ssh $host "yum clean all"
	ssh $host "yum install -y epel-release"
	ssh $host "yum install -y python-pip"
	ssh $host "pip install pymongo"
    ssh $host "unzip agent.zip; cd instance_monitor_agent.git; python setup.py install"
    ssh $host 'sed -i '\'"s/^server_host.*/server_host = \"${server_ip}\"/g"\'' /etc/VMAgent/VMAgent.conf'
	ssh $host 'sed -i '\'"s/^mongodb_host.*/server_host = \"${mongo_ip}\"/g"\'' /etc/VMAgent/VMAgent.conf'
	ssh $host "VMAgent > /dev/null"
done