#!/bin/bash
set -x
script_dir=`dirname $0`
oldpwd=`pwd`
cd $script_dir
scpcmd=scp.sh

if [ $# -lt 3 ]; then
    echo usage $0 [host] [host name] [region]
    exit 1
fi

host=$1
hostname=$2
region=$3


IP=`ssh -G $host | grep -w hostname | awk '{print $2}'`
PORT=`ssh -G $host | grep -w port | awk '{print $2}'`
ssh-keygen -R [$IP]:$PORT

./ssh-copy.sh $host a3f30210

ssh $host "hostnamectl set-hostname $hostname"

ssh $host "cat >> /etc/*bashrc" << EOF

function title() {
  if [[ -z "\$ORIG" ]]; then
    ORIG=\$PS1
  fi
  TITLE="\[\e]2;\$*\a\]"
  PS1=\${ORIG}\${TITLE}
}

title $hostname
EOF

host_ip=`ssh $host "ifconfig eth0" | sed -n 2p | awk '{print $2}'`
$scpcmd openstack-puppet-modules-8.0.4-2.el7.centos.noarch.rpm $host:~/
ssh $host "yum update -y"
ssh $host "yum install -y expect"
ssh $host "yum install -y ~/openstack-puppet-modules-8.0.4-2.el7.centos.noarch.rpm"
ssh $host "yum update -y && \
yum install -y https://repos.fedorapeople.org/repos/openstack/openstack-mitaka/rdo-release-mitaka-5.noarch.rpm && \
yum install -y openstack-packstack && \
service NetworkManager restart"

#ssh $host "packstack --gen-answer-file=answer-file.txt"
cp answer-file.txt answer-file.txt.${host}
sed -i "s/172.23.66.183/${host_ip}/g" answer-file.txt.${host}
sed -i "s/RegionOne/${region}/g" answer-file.txt.${host}
sed -i "s/centos7/${hostname}/g" answer-file.txt.${host}

$scpcmd answer-file.txt.${host} $host:~/
ssh $host "mv answer-file.txt.${host} answer-file.txt"

ssh $host "packstack --answer-file=answer-file.txt"

ssh $host "echo export OS_REGION_NAME=$region >> keystonerc_admin"

# add ServerAlias
ssh $host "sed  -i '/ServerAlias localhost/a \ \ ServerAlias 218.245.64.180' /etc/httpd/conf.d/15-horizon_vhost.conf"
ssh $host "service httpd restart"

cd $oldpwd

