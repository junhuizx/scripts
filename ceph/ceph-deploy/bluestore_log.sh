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
    ceph-deploy osd create  --bluestore --data /dev/sdc --block-wal /dev/sdb $node --debug
  #--bluestore           bluestore objectstore
  #--block-db BLOCK_DB   bluestore block.db path
  #--block-wal BLOCK_WAL
    ceph-deploy osd create --bluestore --data /dev/sdd --block-wal /dev/sde $node --debug
done
ceph osd pool create testbench 128 128
ceph osd pool application enable testbench rbd
ceph osd pool create rbd 256 256
ceph osd pool application enable rbd rbd
