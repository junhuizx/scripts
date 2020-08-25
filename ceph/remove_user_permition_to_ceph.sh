#!/bin/bash
#set -x
BASEDIR=`dirname $BASH_SOURCE`
declare -A cephs
cephs=( [manager]='cn-south-2a-manager-94-20' [compute]='cn-south-2a-compute-80-140' [vm1]='cn-south-2a-ceph-80-211' [oss]='10.4.80.241' )
manager="cn-south-2a-manager-94- 20 22 20 21 22"
compute="cn-south-2a-compute-80- 140 181 148 140 154 168"
#vm1="cn-south-2a-ceph-80- 211 237 218 219 220 228 229 230"
vm1="10.4.80. 211 237 218 219 220 228 229 230 211 221 231"
#oss="cn-south-2a-oss-80- 241 246"
oss="10.4.80. 241 246 241 243 245"
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
keyname=readonly
keyring=ceph.client.$keyname.keyring
targetuser=yovole
declare -A hosts
for ceph in ${!cephs[@]};do
  echo $ceph
  hosts[$ceph]=$(gen_hosts "" $(eval echo \$$ceph ))
  mon=${cephs[$ceph]}
  ssh root@$mon ceph auth rm client.$keyname
  for host in ${hosts[$ceph]};do
    ssh root@$host rm -f /etc/ceph/ceph.client.$keyname.keyring
    #ssh root@$host 'sed -i '\''s/alias ceph=.*//g'\'' /home/'$targetuser'/.bashrc'
    ssh root@$host cp -f /home/$targetuser/.bashrc.bak /home/$targetuser/.bashrc
    ssh root@$host 'su - '$targetuser' -c "ceph -n client.readonly -s"' && exit 1
  done
done
echo done



