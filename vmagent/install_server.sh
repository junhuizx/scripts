#!/bin/bash
set -x

if [[ $# < 2 ]]; then
    echo usage: $0 [server ip] [auth url]
    exit 1
fi
server_ip=$1
auth_url=`echo https://172.23.64.45:8083/api/user/checkToken?token= | sed 's$172.23.64.45:8083$'$2'$g'`

yum install -y epel-release
yum install -y git vim
yum install -y mariadb-server mariadb python-pip supervisor nginx python-devel MySQL-python gcc
yum install -y mongodb-server mongodb
sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/g' /etc/mongod.conf
sed -i 's/bind_ip = 127.0.0.1/bind_ip = 0.0.0.0/g' /etc/mongod.conf
cat >>  /etc/security/limits.conf  << EOF
mongod soft fsize unlimited
mongod hard fsize unlimited
mongod soft cpu unlimited
mongod hard cpu unlimited
mongod soft as unlimited
mongod hard as unlimited
mongod soft nofile 64000
mongod hard nofile 64000
mongod soft nproc 64000
mongod hard nproc 64000
EOF
 
 
systemctl enable mongod
systemctl start mongod

systemctl start mariadb

mysql -uroot -e "CREATE DATABASE vmserver DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci; GRANT ALL privileges ON vmserver.* TO 'vmserver'@'%' IDENTIFIED BY 'vmserver';"

git clone https://git.newtouch.com/user6358/instance_monitor_server.git
mv instance_monitor_server/ /var/www/
cd /var/www/instance_monitor_server/
pip install -r requestments.txt

sed -i 's/'\''HOST'\'': '\''[^'\'']*'\''/'\''HOST'\'': '\'${server_ip}\''/g' /var/www/instance_monitor_server/instance_monitor_server/settings.py
sed -i 's$^AUTH_URL.*$AUTH_URL='\'${auth_url}\''$g' /var/www/instance_monitor_server/instance_monitor_server/settings.py
sed -i 's/^MONGODB_HOST.*/MONGODB_HOST='\'${server_ip}\''/g' /var/www/instance_monitor_server/instance_monitor_server/settings.py
pwd
ls
cp vmserver.conf /etc/nginx/conf.d/vmserver.conf
sed -i 's/80 default_server/8888 default_server/g' /etc/nginx/nginx.conf
cp supervisor-app.ini  /etc/supervisord.d/supervisor-app.ini
python manage.py migrate
python manage.py createsuperuser --username admin --email admin@localhost
supervisord
service nginx restart

