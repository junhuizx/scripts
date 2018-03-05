#!/bin/bash
set -x
base=`dirname $0`
base=`cd $base;pwd`
cd -


cd $GOPATH/src/github.com/open-falcon/falcon-plus/
mkdir -p old_packages
mv open-falcon*.tar.gz old_packages/
rm -rf  open-falcon*.tar.gz
make
make pack
mkdir -p $base/out/falcon
cp open-falcon*.tar.gz $base/out/falcon/
for module in hbs-proxy  mail-provider  ops-updater; do
	cd $GOPATH/src/github.com/open-falcon/$module
	go get ./...
	./control build
	./control pack
	mkdir $base/out/falcon/$module
	cp falcon-${module}*.tar.gz $base/out/falcon/$module/
	cd $base/out/falcon/$module/
	tar xf falcon-${module}*.tar.gz
	rm falcon-${module}*.tar.gz
done
cp $GOPATH/src/github.com/open-falcon/dashboard $base/out/falcon/ -rf
cd $base/out/falcon
tar xf open-falcon*.tar.gz
rm -rf open-falcon*.tar.gz
cd agent
git clone https://code.newtouch.com/M6X27IA9/plugin.git
cd ../..
tar cf falcon.tar.gz falcon
cd falcon/agent
sed -i 's/"debug".*/"debug": false,/' agent/config/cfg.json
sed -ri '/"plugin"/,/\}/s/"enabled".*/"enabled": true,/' config/cfg.json
sed -ri '/"http"/,/\}/s/"enabled".*/"enabled": false,/' config/cfg.json
sed -i 's/"ifacePrefix".*/"ifacePrefix": ["eth", "em", "en", "bound", "br-ex"],/' config/cfg.json
sed -ri '/"ignore"/,/\}/{/[\{\}]/! d}' config/cfg.json
cd ..
tar cf agent.tar.gz agent
mv agent.tar.gz ../
cd $base
