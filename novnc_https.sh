#!/usr/bin/env bash
set -x

mkdir ssl
openssl genrsa -out ssl/server.key 2048
openssl req -new -key ssl/server.key -out ssl/server.csr
openssl req -x509 -days 365 -key ssl/server.key -in ssl/server.csr -out ssl/server.crt
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
systemctl restart httpd openstack-nova-novncproxy