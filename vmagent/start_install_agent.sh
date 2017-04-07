#!/bin/bash

source keystonerc_admin
mkdir vmagent
cd vmagent
curl https://raw.githubusercontent.com/junhuizx/scripts/master/vmagent/install_agent.sh -o install_agent.sh
chmod +x install_agent.sh
./install_agent.sh $*


