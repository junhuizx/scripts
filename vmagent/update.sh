#!/bin/bash
set -x

ct=172.23.1.60
localip=172.23.1.98
base=`dirname $0`

alias ssh='ssh -o StrictHostKeyChecking=no'
alias scp='scp -o StrictHostKeyChecking=no'

${base}/update_server.sh

ssh $ct "rm -rf ~/vmagent_update; mkdir ~/vmagent_update"
scp ${base}/update_agent.sh $ct:~/vmagent_update/
ssh $ct "source keystone*admin; cd ~/vmagent_update/; ./update_agent.sh $localip $localip"

