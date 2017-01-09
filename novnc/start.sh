#!/bin/bash

source keystonerc_admin
yum install -y wget unzip
mkdir vnc
cd vnc
wget https://github.com/junhuizx/scripts/archive/master.zip
unzip master.zip
cd scripts-master/novnc/
unzip ssl.zip

./novnc_https.sh


