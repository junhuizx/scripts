#!/usr/bin/python

import time
import sys

percent = int(sys.argv[1]) if len(sys.argv)>=2 else 100
percent = 1 if percent==0 else percent
r = (100-percent)*0.9/percent
while True:
    start=time.time()
    sum=0
    for i in range(1000):
        sum += i
    t = time.time()-start
    time.sleep(t * r)
