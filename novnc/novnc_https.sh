#!/usr/bin/env bash
set -x

if [ ! -d ssl ]; then
	mkdir ssl
	openssl genrsa -out ssl/server.key 2048
	openssl req -new -key ssl/server.key -out ssl/server.csr  -subj /C=CN/ST=newtouch/L=newtouch/O=ntx/CN=newtouch.com
	openssl req -x509 -days 3650 -key ssl/server.key -in ssl/server.csr -out ssl/server.crt
fi

sshcmd="ssh -o StrictHostKeyChecking=no"
scpcmd="scp -o StrictHostKeyChecking=no"
source keystonerc_admin
for host in `nova service-list --binary nova-consoleauth  | awk -F\| '{if($2~"[0-9]+")print $4}'`; do
	sshcmd_host="$sshcmd $host"
	$scpcmd -r ssl $host:/etc/nova/
	$sshcmd_host 'sed -i  '\''/#ssl_only *= *false/{n;/^ *ssl_only/'\!'{i \ssl_only=true
	}}'\'' /etc/nova/nova.conf'
	$sshcmd_host 'sed -i  '\''/#cert=self.pem/{n;/^ *cert/'\!'{i \cert=/etc/nova/ssl/server.crt
	}}'\'' /etc/nova/nova.conf'
	$sshcmd_host 'sed -i  '\''/#key=<None>/{n;/^ *key/'\!'{i \key=/etc/nova/ssl/server.key
	}}'\'' /etc/nova/nova.conf'
	$sshcmd_host 'sed -i  '\''s/^novncproxy_base_url *= *http:/novncproxy_base_url=https:/g'\'' /etc/nova/nova.conf'
	$sshcmd_host 'sed -i  '\''/s.innerHTML *= *msg;/{n;/^ *if(/'\!'{i \                if\(msg.indexOf\("Connected"\) == 0\)\{
	i \                    s.innerHTML = "";
	i \                \}
	}}'\'' /usr/share/novnc/vnc_auto.html'
	$scpcmd terminal.html $host:/usr/share/novnc/

	$sshcmd_host 'systemctl restart openstack-nova-novncproxy'
done

for host in `nova service-list --binary nova-compute  | awk -F\| '{if($2~"[0-9]+")print $4}'`; do
openstack hypervisor show $host -c host_ip | grep host_ip | awk '{print $4}'
$sshcmd $host "sed -i  's/^novncproxy_base_url *= *http:/novncproxy_base_url=https:/g' /etc/nova/nova.conf; systemctl restart openstack-nova-compute"
done
