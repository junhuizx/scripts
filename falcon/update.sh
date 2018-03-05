#!/bin/bash
set -x
base=`dirname $0`
base=`cd $base;pwd`
cd -
if [[ $# == 1 ]]; then
	dst=`cd $1; pwd`
	cd -
else
	dst=/var/lib/falcon
fi
src=falcon
mkdir /tmp/falcon
cd /tmp/falcon

url="http://218.245.64.188:8000/falcon/falcon.tar.gz"
curl $url -o falcon.tar.gz
tar xf falcon.tar.gz
#stop
for module in agent aggregator alarm api dashboard gateway graph hbs hbs-proxy judge mail-provider nodata ops-updater transfer;do
	systemctl stop falcon-$module
done
for module in agent aggregator alarm api gateway graph hbs judge nodata transfer ; do
	cp $src/$module/bin/* $dst/$module/bin/
done
for module in hbs-proxy mail-provider ops-updater; do
	cp $src/$module/control $dst/$module/ -f
	cp $src/$module/falcon-$module $dst/$module/ -f
done
#cp $src/dashboard $dst/ -ru

rm -rf /tmp/falcon
for module in agent aggregator alarm api dashboard gateway graph hbs hbs-proxy judge mail-provider nodata ops-updater transfer;do
	systemctl start falcon-$module
done
cd -
