#!/bin/bash
i=0
while [ $i -le "31" ]
do
i=$((${i}+1))
echo -----------------$i----------
#ssh 172.26.0.$i " ifconfig enp2s0f0|grep 172.26"
#ssh 172.26.0.$i "sed -i s/255.255.254.0/255.255.240.0/g /etc/sysconfig/network-scripts/ifcfg-enp2s0f1"
#ssh 172.26.0.$i  "service network restart"
#ssh 172.26.0.$i "route -n|grep 172.26.255.254"
#"sar -n DEV 1 1|grep enp7s0f0"
#./ssh-copy.sh 172.23.0.$i
#"nova boot --flavor 68ffdfcb-662b-4cc8-8ba1-c682e49fbffb --image 5352e67b-a7bd-4e02-abee-f793df5d87cd --nic net-id=fee9e01b-a485-4881-b4ac-da3b6bf0afb4 --security-group default  --availability-zone nova demo-instance0001"
#ssh 172.20.0.$i "systemctl stop ntpd && systemctl disable ntpd"
#ssh 172.25.0.$i " egrep 'NETMASK|GATEWAY' /etc/sysconfig/network-scripts/ifcfg-enp2s0f0 "
#ssh 172.23.0.$i " service network restart"
#ssh 172.19.64.$i "sed s/172.22/172.23/g /etc/sysconfig/network-scripts/ifcfg-enp2s0f0 -i "
#ssh 172.23.0.$i "hostname && date && hwclock"
ssh 172.23.0.$i "cat /etc/resolv.conf"
#ssh 172.19.48.$i "/usr/bin/rdate -s time.nist.gov && hwclock -w"
#ssh 172.20.0.$i "cat /etc/resolv.conf"
#ssh 172.23.0.$i "service  openstack-nova-compute restart"
#ssh 172.23.0.$i "service neutron-openvswitch-agent restart"
#ssh 172.17.0.$i "cat /etc/ceph/ceph.conf |grep fsid"
#ssh 172.23.0.$i "rsync -avP /etc/yum.repos.d/bak/ /etc/yum.repos.d/"
#ssh 172.23.0.$i "yum install  python-ceph -y"
#ssh 172.17.0.$i  "service openstack-nova-compute start;service neutron-l3-agent start;service neutron-metadata-agent start;service neutron-openvswitch-agent start"
#ssh 172.17.0.$i "systemctl disable openstack-ceilometer-compute"
#ssh 172.17.0.$i "service openstack-ceilometer-compute status|grep Active"
#ssh 172.23.0.$i " ls -l /etc/neutron/neutron.conf"
#ssh 172.20.0.$i " yum clean all"
#ssh 172.17.0.$i "yum install -y redhat-lsb-core"
#ssh 172.17.0.$i "systemctl restart openstack-nova-compute"
#ssh 172.20.0.$i "systemctl status neutron-openvswitch-agent |grep active"
#ssh 172.17.0.$i "yum install -y ceph-common python-ceph "
#ssh 172.17.0.$i " sed -i s/rabbit_hosts=172.17.0.170:5672/rabbit_hosts=172.17.0.5:5672,172.17.0.170:5672/g /etc/nova/nova.conf"
#ssh 172.17.0.$i "ls /etc/ceph/ceph.mon.keyring|grep ceph.mon.keyring"
###############hostname################
#aa=`ssh 172.23.0.$i ifconfig |grep 172.23|awk '{print $2}'`
#name=`egrep   $aa /etc/hosts|head -n 1 |awk '{print $2}'`
#ssh 172.23.0.$i "echo $name > /etc/hostname "
#ssh 172.23.0.$i "hostname $name"
#ssh 172.23.0.$i "cat /etc/hostname"
#sh 172.20.0.$i "rm -rf /etc/yum.repos.d/*.repo"
#ssh 172.20.0.$i "yum clean all"
##################################

#name=`ssh 172.23.0.$i hostname`

#ssh 172.23.0.$i "sed -i s/fx2cp011/$name/g /etc/nova/nova.conf"
#ssh 172.23.0.$i "cat /etc/nova/nova.conf |grep vncserver_proxyclient_address"
#ssh 172.20.0.$i "service iptables stop"
#ssh 172.20.0.$i "cat /etc/yum.repos.d/rdo-release.repo  |grep baseurl"


done
exit
