#!/bin/bash
set -x

src=$1
dst=$2
host=
is_remote_src=
src=${src%/}
tar_flag=" -h"
if [[ $src =~ ":" ]] ; then
    host=`echo $src | awk -F: '{print $1}'`
    src=`echo $src | awk -F: '{print $2}'`
    is_remote_src=true
fi
if [[ $dst =~ ":" ]] ; then
    host=`echo $dst | awk -F: '{print $1}'`
    dst=`echo $dst | awk -F: '{print $2}'`
fi
src_dir=`dirname $src`
if [ -z $host ]; then
    echo need a remote host
    exit 1
fi
src_basename=`basename ${src}`
src_tar=${src_basename}.tar
tar_file=`echo ${src}.tar | awk -F/ '{print $NF}'`
if [ -z $is_remote_src ] ; then
    cd $src_dir
    tar cf $src_tar $src_basename ${tar_flag}
    scp $src_tar ${host}:${dst}
#    if ssh $host "test -f $dst"; then
#        ssh $host "mv $dst ${dst}.tar"
#        ssh ${host} "tar xf ${dst}.tar"
#    fi
    ssh ${host} "tar xf ${dst}/${tar_file} -C ${dst}"
    ssh ${host} "rm ${dst}/${tar_file}"
    rm $src_tar
    cd -
else
    ssh $host "cd $src_dir; tar cf $src_tar $src_basename ${tar_flag}"
    scp ${host}:${src_dir}/${src_tar} ${dst}
    tar xf ${dst}/${tar_file} -C ${dst}
    rm ${dst}/${tar_file}
    ssh ${host} "cd $src_dir; rm $src_tar"
fi

