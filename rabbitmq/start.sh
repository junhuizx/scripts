#!/bin/bash

python notifications_comsuer.py grep rabbit_hosts /etc/neutron/neutron.conf | grep -v \# | awk -F\= '{print $2}' | awk -F, '{print $1}' | awk -F: '{print $1,$2}'172.17.0.5 5672
