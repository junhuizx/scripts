#!/bin/bash
python notifications_consumer.py `grep rabbit_hosts /etc/neutron/neutron.conf | grep -v \# | awk -F\= '{print $2}' | awk -F, '{print $1}' | awk -F: '{print $1,$2}'` &
