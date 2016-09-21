#!/bin/bash
set -x

src=$1
dst=$2
host=
is_remote_src=
src=${src%/}
if [[ $src =~ ":" ]] ; then
    host=`echo $src | awk -F: '{print $1}'`
    src=`echo $src | awk -F: '{print $2}'`
    is_remote_src=true
fi
if [[ $dst =~ ":" ]] ; then
    host=`echo $dst | awk -F: '{print $1}'`
    dst=`echo $dst | awk -F: '{print $2}'`
fi
if [ -z $host ]; then
    echo need a remote host
    exit 1
fi
if [ -z $is_remote_src ] ; then
    src_tar=${src}.tar
    tar_file=`echo ${src}.tar | awk -F/ '{print $NF}'`
    tar cf $src_tar $src
    scp $src_tar ${host}:${dst}
#    if ssh $host "test -f $dst"; then
#        ssh $host "mv $dst ${dst}.tar"
#        ssh ${host} "tar xf ${dst}.tar"
#    fi
    ssh ${host} "tar xf ${dst}/${tar_file}"
    ssh ${host} "rm ${dst}/${tar_file}"
    rm $src_tar
else
    src_tar=${src}.tar
    tar_file=`echo ${src}.tar | awk -F/ '{print $NF}'`
    ssh $host "tar cf $src_tar $src"
    scp ${host}:${src_tar} ${dst}
    tar xf ${dst}/${tar_file}
    rm ${dst}/${tar_file}
    ssh ${host} "rm $src_tar"
fi

