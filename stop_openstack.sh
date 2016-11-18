#!/usr/bin/env bash


systemctl -a | grep openstack | awk '{if($1=="●")print $2; else print $1}' | xargs -n1 systemctl stop
systemctl -a | grep neutron | awk '{if($1=="●")print $2; else print $1}' | xargs -n1 systemctl stop
systemctl stop httpd