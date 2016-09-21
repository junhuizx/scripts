#!/bin/bash
i=2
while [ $i -le "31" ]
do
i=$((${i}+1))
echo 172.23.0.$i
#rsync -avP /etc/ceph/  172.18.0.$i:/etc/ceph
#ssh  172.17.0.$i 'yum install ceph-common python-ceph -y '
#rsync -avP /var/spool/cron/root  172.17.0.$i:/var/spool/cron
rsync -avP /etc/resolv.conf  172.23.0.$i:/etc/
#rsync -avP /etc/ceph/   172.23.0.$i:/etc/ceph
#rsync -avP /etc/yum.repos.d/CentOS-OpenStack-mitaka.repo  172.23.0.$i:/etc/yum.repos.d
#rsync -avP /etc/hosts 172.23.0.$i:/etc/
#rsync -avP   neutron.conf 172.17.0.$i:/etc/neutron/neutron.conf
#rsync -avP /etc/yum.repos.d/CentOS-OpenStack-mitaka.repo  172.23.0.$i:/etc/yum.repos.d/
#rsync -avP   neutron.conf 172.23.0.$i:/etc/neutron/neutron.conf
#rsync -avP   nova.conf 172.23.0.$i:/etc/nova/nova.conf

done
exit
