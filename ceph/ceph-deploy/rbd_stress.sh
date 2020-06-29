#!/bin/bash
set -x
imagename=test$HOSTNAME
#iototal=4294967296
iototal=1G
if ! rbd ls | grep test$HOSTNAME;then
    rbd create --size 100G  $imagename
fi
echo ==============================4K rw========================  > rbdbench.out
rbd bench testceph_ec_test_mon_1 --io-total $iototal --io-size 4096 --io-threads 12 --io-type rw --rw-mix-read 70 --io-pattern rand >> rbdbench.out
echo -e "\n\n\n" >> rbdbench.out

echo ==============================4K write======================  >> rbdbench.out
rbd bench $imagename --io-total $iototal --io-type write --io-size 4096 --io-threads 12 --io-pattern rand >> rbdbench.out
echo -e "\n\n\n" >> rbdbench.out

echo ==============================4K read======================  >> rbdbench.out
rbd bench $imagename --io-total $iototal --io-type read --io-size 4096 --io-threads 12 --io-pattern rand >> rbdbench.out
echo -e "\n\n\n" >> rbdbench.out

echo ==============================64K rw========================  > rbdbench.out
rbd bench testceph_ec_test_mon_1 --io-total $iototal --io-size 65536 --io-threads 12 --io-type rw --rw-mix-read 50 --io-pattern rand >> rbdbench.out
echo -e "\n\n\n" >> rbdbench.out

echo ==============================64K write======================  >> rbdbench.out
rbd bench $imagename --io-total $iototal --io-type write --io-size 65536 --io-threads 12 --io-pattern rand >> rbdbench.out
echo -e "\n\n\n" >> rbdbench.out

echo ==============================64K read======================  >> rbdbench.out
rbd bench $imagename --io-total $iototal --io-type read --io-size 65536 --io-threads 12 --io-pattern rand >> rbdbench.out
echo -e "\n\n\n" >> rbdbench.out


echo ==============================4M write========================  >> rbdbench.out
rbd bench $imagename --io-total $iototal --io-type write --io-size 4194304 --io-threads 12 --io-pattern seq >> rbdbench.out
echo -e "\n\n\n" >> rbdbench.out

echo ==============================4m read======================  >> rbdbench.out
rbd bench $imagename --io-total $iototal --io-type read --io-size 4194304 --io-threads 12 --io-pattern seq >> rbdbench.out
echo -e "\n\n\n" >> rbdbench.out



