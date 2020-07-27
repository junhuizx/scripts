#!/bin/bash
set -x
BASEDIR=`dirname $BASH_SOURCE`
. $BASEDIR/ceph_def.sh
piblic_network=10.2.13.0/24
cluster_network=192.168.4.0/24
ceph-deploy new $mons --public-network ${piblic_network} --cluster-network {cluster_network}
cat $BASEDIR/other.conf >> $BASEDIR/ceph.conf
ceph-deploy install $hosts --no-adjust-repos
ceph-deploy --overwrite-conf mon create-initial
ceph-deploy admin $hosts
if [[ -n $mgrs ]]; then
    ceph-deploy mgr create $mgrs
fi
if [[ -n $rgws ]]; then
    ceph-deploy rgws $rgws
fi

