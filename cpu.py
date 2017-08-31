#!/usr/bin/python

import time
import sys
import multiprocessing as mp
import argparse

def cpu(percent):
    r = (100-percent)*0.9/percent
    while True:
        start=time.time()
        sum=0
        for i in range(1000):
            sum += i
        t = time.time()-start
        time.sleep(t * r)

def main():
    #parser = argparse.ArgumentParser()
    #parser.add_argument('-p', '--percent', help='used percent')
    cpu_count = mp.cpu_count()
    percent = int(sys.argv[1]) if len(sys.argv)>=2 else 100
    percent = percent * cpu_count
    num = percent/100
    percent = percent%100
    percent = 1 if percent==0 else percent
    process_list=[]
    for i in range(num):
        process_list.append(mp.Process(target=cpu, args=(100,)))
        process_list[-1].start()
    try:
        cpu(percent)
    except:
        for p in process_list:
            p.terminate()
        raise


if __name__ == "__main__":
    main()
