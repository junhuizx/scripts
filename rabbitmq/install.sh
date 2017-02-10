#!/bin/bash

# use curl https://raw.githubusercontent.com/junhuizx/scripts/master/rabbitmq/install.sh | bash
# to install this
mkdir rabbitmq_consumer
cd rabbitmq_consumer
yum -y install  wget python-pip
pip install pika
wget https://github.com/junhuizx/scripts/archive/master.zip
unzip master.zip
cd scripts-master/rabbitmq/

./start.sh

