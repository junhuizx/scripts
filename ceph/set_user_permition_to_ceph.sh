#!/bin/bash
set -x
BASEDIR=`dirname $BASH_SOURCE`
if [ $# -lt 2 ];then
  echo usage: $0 [ceph custer defile rc file]
  exit 1
fi
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

. $1

exit

declare -A hosts
for ceph in ${!cephs[@]};do
  echo $ceph
  hosts[$ceph]=$(eval echo \$${ceph}_hosts)
  if [ -z ${hosts[$ceph]} ];then
    hosts[$ceph]=$(gen_hosts "" $(eval echo \$$ceph ))
  fi
  mon=${cephs[$ceph]}
  if ! ssh root@$mon ceph auth get client.$keyname > /dev/null 2>/dev/null; then
    ssh root@$mon ceph auth add client.$keyname "$caps"
    ssh root@$mon ceph auth get client.$keyname -o /tmp/$keyring
    scp root@$mon:/tmp/$keyring $BASEDIR/$keyring.$ceph
    ssh root@$mon rm /tmp/$keyring -f
    ssh root@$mon ceph auth list | grep -C 4 $keyname > /dev/null || exit 1
  fi
  for host in ${hosts[$ceph]};do
    if ! ssh root@$host ls /etc/ceph/$keyring > /dev/null 2>/dev/null ; then
      scp $BASEDIR/$keyring.$ceph root@$host:/etc/ceph/$keyring
      ssh root@$host chmod 600 /etc/ceph/$keyring
      for targetuser in $targetuser; do
        targetuserhome=`ssh root@host awk -F: '{if($1=="'$targetuser'")print $6}' /etc/passwd`
        if [ -n $targetuserhome ];then
          ssh root@$host setfacl -m u:$targetuser:r /etc/ceph/$keyring
          ssh root@$host cp /home/$targetuser/.bashrc /home/$targetuser/.bashrc.bak
          ssh root@$host 'grep readonly /home/'$targetuser'/.bashrc >/dev/null || echo '\''alias ceph="ceph -n client.readonly"'\'' >> /home/'$targetuser'/.bashrc'
          ssh root@$host 'su - '$targetuser' -c "ceph -n client.readonly -s"' || exit 1
          ssh root@$host 'su - '$targetuser' -c "ceph -n client.readonly auth list"' && exit 1
        fi
      done
    fi

  done
done
echo done
