#!/bin/bash

if [[ z$1 == z ]];then
	outdir=openstack_clone
else
	outdir=$1
fi
mkdir -p $outdir
cd $outdir
out=cgit.html
curl -o $out http://git.openstack.org/cgit
exec_openstack_clone=exec_openstack_clone.sh
echo '#!/bin/bash' > $exec_openstack_clone
grep "title=" $out  | sed  's#^.*title='\''\([^0-9][^'\'']\+\)'\''.*$#git clone git://git.openstack.org/\1#g' >> $exec_openstack_clone
chmod +x $exec_openstack_clone
./$exec_openstack_clone
