#!/bin/bash

ceph osd crush add-bucket default root
ceph osd crush add-bucket rack1 rack ;
ceph osd crush move rack1 root=default ;
ceph osd crush add-bucket yc-beta-1-monitor-1-121 host;
ceph osd crush move yc-beta-1-monitor-1-121 rack=rack1 ;
ceph osd crush add osd.0 3.6 host=yc-beta-1-monitor-1-121
ceph osd crush add osd.1 3.6 host=yc-beta-1-monitor-1-121
ceph osd crush add osd.2 3.6 host=yc-beta-1-monitor-1-121
ceph osd crush add osd.3 3.6 host=yc-beta-1-monitor-1-121

ceph osd crush add-bucket rack2 rack ;
ceph osd crush move rack2 root=default ;
ceph osd crush add-bucket yc-beta-1-monitor-1-122 host;
ceph osd crush move yc-beta-1-monitor-1-122 rack=rack2 ;
ceph osd crush add osd.4 3.6 host=yc-beta-1-monitor-1-122
ceph osd crush add osd.5 3.6 host=yc-beta-1-monitor-1-122
ceph osd crush add osd.6 3.6 host=yc-beta-1-monitor-1-122


ceph osd crush add-bucket rack3 rack ;
ceph osd crush move rack3 root=default ;
ceph osd crush add-bucket yc-beta-1-monitor-1-123 host;
ceph osd crush move yc-beta-1-monitor-1-123 rack=rack3 ;
ceph osd crush add osd.7 3.6 host=yc-beta-1-monitor-1-123
ceph osd crush add osd.8 3.6 host=yc-beta-1-monitor-1-123
ceph osd crush add osd.9 3.6 host=yc-beta-1-monitor-1-123
ceph osd crush add osd.10 3.6 host=yc-beta-1-monitor-1-123

ceph osd pool delete rbd rbd --yes-i-really-really-mean-it

ceph osd pool create vms_hdd 256 256 replicated
#ceph osd pool application enable vms_hdd rbd
ceph osd pool create images 128 128 replicated
#ceph osd pool application enable images rbd
ceph osd pool create vms_bak 128 128 replicated
#ceph osd pool application enable vms_bak rbd
