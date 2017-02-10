#!/bin/bash

mkdir rabbitmq_consumer
cd rabbitmq_consumer
yum install -y wget
pip install pika
wget https://github.com/junhuizx/scripts/archive/master.zip
unzip master.zip
cd scripts-master/rabbitmq/

./start.sh

