#!/bin/bash
cd /var/www/instance_monitor_server
git pull
supervisorctl restart all
cd -
