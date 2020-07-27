#!/bin/bash
set -x
BASEDIR=`dirname $BASH_SOURCE`
. $BASEDIR/ceph_def.sh

journals=()
disks=( sdb sdc )
wals=()
dbs=()
#osds="node1 node2"
disks_node1=( sde sdf )
debug="--debug"
osd_cmd='ceph-deploy osd create --bluestore --data /dev/${disk} --block-db ${db} $node $debug'
osd_cmd='ceph-deploy osd create --filestore --data /dev/${disk} --journal /dev/${journal} --fs-type xfs $node $debug'
osd_cmd='ceph-deploy osd create --filestore --data /dev/${disk} --fs-type xfs $node $debug'
for node in $osds;do
  node_journals=$(eval echo '${'journals_$node'[*]}')
  node_journals=${node_journals:-${journals[*]}}
  node_disks=$(eval echo '${'disks_$node'[*]}')
  node_disks=${node_disks:-${disks[*]}}
  node_wals=$(eval echo '${'wals_$node'[*]}')
  node_wals=${node_wals:-${wals[*]}}
  node_dbs=$(eval echo '${'dbs_$node'[*]}')
  node_dbs=${node_dbs:-${dbs[*]}}
  for disk in $node_disks;do

  done
done
