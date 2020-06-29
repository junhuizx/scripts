#!/bin/bash
BASEDIR=`dirname $0`
hosts=`cat $BASEDIR/hosts`
mons=`cat $BASEDIR/mon_hosts`
mgrs=$mons
ceph-deploy new $mons
cat $BASEDIR/other.conf >> $BASEDIR/ceph.conf
for node in $hosts ;do
    scp ceph.repo $node:/etc/yum.repos.d/ceph.repo
done
ceph-deploy install $hosts
ceph-deploy mon create-initial
ceph-deploy admin $hosts
ceph-deploy mgr create $mgrs
for node in $hosts; do
    ceph-deploy osd create  --bluestore --data /dev/sdc $node --debug
  #--bluestore           bluestore objectstore
  #--block-db BLOCK_DB   bluestore block.db path
  #--block-wal BLOCK_WAL
    ceph-deploy osd create --bluestore --data /dev/sdd $node --debug
done
ceph osd pool create testbench 128 128
ceph osd pool create rbd 256 256
