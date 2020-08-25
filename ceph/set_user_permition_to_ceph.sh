#!/bin/bash
set -x
BASEDIR=`dirname $BASH_SOURCE`
declare -A cephs
cephs=( [manager]='cn-south-2a-manager-94-20' [compute]='cn-south-2a-compute-80-140' [vm1]='cn-south-2a-ceph-80-211' [oss]='10.4.80.241' )
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
keyname=readonly
keyring=ceph.client.$keyname.keyring
targetuser=yovole
declare -A hosts
for ceph in ${!cephs[@]};do
  echo $ceph
  hosts[$ceph]=$(gen_hosts "" $(eval echo \$$ceph ))
  mon=${cephs[$ceph]}
  if ! ssh root@$mon ceph auth get client.$keyname > /dev/null 2>/dev/null; then
    ssh root@$mon ceph auth add client.$keyname mon '"allow r" mgr "allow r" osd "allow r"'
    ssh root@$mon ceph auth get client.$keyname -o /tmp/$keyring
    scp root@$mon:/tmp/$keyring $BASEDIR/$keyring.$ceph
    ssh root@$mon rm /tmp/$keyring -f
    ssh root@$mon ceph auth list | grep -C 4 $keyname > /dev/null || exit 1
    #ssh root@$mon ceph auth list | grep -C 4 $keyname
  fi
  for host in ${hosts[$ceph]};do
    if ! ssh root@$host ls /etc/ceph/$keyring > /dev/null 2>/dev/null ; then
      scp $BASEDIR/$keyring.$ceph root@$host:/etc/ceph/$keyring
      ssh root@$host chmod 600 /etc/ceph/$keyring
      ssh root@$host setfacl -m u:$targetuser:r /etc/ceph/$keyring
      ssh root@$host cp /home/$targetuser/.bashrc /home/$targetuser/.bashrc.bak
      ssh root@$host 'grep readonly /home/'$targetuser'/.bashrc >/dev/null || echo '\''alias ceph="ceph -n client.readonly"'\'' >> /home/'$targetuser'/.bashrc'
    fi
    ssh root@$host 'su - '$targetuser' -c "ceph -n client.readonly -s"' || exit 1
    ssh root@$host 'su - '$targetuser' -c "ceph -n client.readonly auth list"' && exit 1
  done
done
echo done
