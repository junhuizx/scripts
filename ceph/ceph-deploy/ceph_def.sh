#!/bin/bash
BASEDIR=`dirname $BASH_SOURCE`
export hosts=`cat $BASEDIR/hosts`
export mons=`cat $BASEDIR/mon_hosts`
export osds=`cat $BASEDIR/osd_hosts`
export rgw=`cat $BASEDIR/rgw_hosts`
export mgrs=$monss