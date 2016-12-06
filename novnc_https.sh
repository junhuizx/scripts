#!/usr/bin/env bash
set -x

mkdir ssl
openssl genrsa -out ssl/server.key 2048
openssl req -new -key ssl/server.key -out ssl/server.csr  -subj /C=CN/ST=newtouch/L=newtouch/O=ntx/CN=newtouch.com
openssl req -x509 -days 3650 -key ssl/server.key -in ssl/server.csr -out ssl/server.crt
cp -r ssl /etc/nova/
sed -i  '/#ssl_only *= *false/{n;/^ *ssl_only/'\!'{i \ssl_only=true
}}' /etc/nova/nova.conf
sed -i  '/#cert=self.pem/{n;/^ *cert/'\!'{i \cert=/etc/nova/ssl/server.crt
}}' /etc/nova/nova.conf
sed -i  '/#key=<None>/{n;/^ *key/'\!'{i \key=/etc/nova/ssl/server.key
}}' /etc/nova/nova.conf
sed -i  's/^novncproxy_base_url *= *http:/novncproxy_base_url=https:/g' /etc/nova/nova.conf
sed -i '/s.innerHTML *= *msg;/{n;/^ *if(/'\!'{i \                if\(msg.indexOf\("Connected"\) == 0\)\{
i \                    s.innerHTML = "";
i \                \}
}}' /usr/share/novnc/vnc_auto.html
systemctl restart openstack-nova-novncproxy

source keystonerc_admin
for host in `openstack hypervisor list | awk -F\| '{if($2~"[0-9]+")print $3}'`; do
openstack hypervisor show $host -c host_ip | grep host_ip | awk '{print $4}'
ssh $host "sed -i  's/^novncproxy_base_url *= *http:/novncproxy_base_url=https:/g' /etc/nova/nova.conf; systemctl restart openstack-nova-compute"
done