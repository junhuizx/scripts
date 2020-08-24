#!/bin/bash
#set -x
cephs="cn-south-2a-manager-94-20 cn-south-2a-compute-80-140 cn-south-2a-ceph-80-211 10.4.80.241"
manager="cn-south-2a-manager-94- 20 22"
compute="cn-south-2a-compute-80- 140 181 148"
#vm1="cn-south-2a-ceph-80- 211 237 218 219 220 228 229 230"
vm1="10.4.80. 211 237 218 219 220 228 229 230"
#oss="cn-south-2a-oss-80- 241 246"
oss="10.4.80. 241 246"
function gen_hosts(){
  out_hosts=$1
  prefix=$2
  start=$3
  end=$4
  shift 4
  exceptions="$*"
  for i in `seq $start $end`;do
    if ! echo $exceptions | grep -w $i >/dev/null;then
      out_hosts="$out_hosts ${prefix}$i"
    fi
  done
  echo $out_hosts
}
all=`gen_hosts "$all" $manager`
all=`gen_hosts "$all" $compute`
all=`gen_hosts "$all" $vm1`
all=`gen_hosts "$all" $oss`
keyname=readonly
for ceph in $cephs;do
  ssh root@$ceph ceph auth rm client.$keyname
  ssh root@$ceph rm -f /etc/ceph/ceph.client.$keyname.keyring
done
targetuser=yovole
#all=$cephs
for host in $all;do
  ssh root@$host rm -f /etc/ceph/ceph.client.$keyname.keyring
  #ssh root@$host 'sed -i '\''s/alias ceph=.*//g'\'' /home/'$targetuser'/.bashrc'
  ssh root@$host cp -f /home/$targetuser/.bashrc.bak /home/$targetuser/.bashrc
  ssh root@$host 'su - '$targetuser' -c "ceph -n client.readonly -s"' && exit 1
done
echo done
