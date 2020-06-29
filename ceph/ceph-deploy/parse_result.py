#!/usr/bin/python
import os, sys
#import plt
import re
from collections import OrderedDict as od

sep=re.compile(r"=+([^=]+)=+")
bench_info=re.compile(r"bench  type.+")
def parse(files):
    result=od()
    for file in files:
        with open(file) as f:
            result[file]=od()
            key=None
            for line in f.readlines():
                r = sep.match(line)
                if r:
                    key = r.groups()[0]
                    result[file][key]=od()
                    continue
                r = bench_info.match(line)
                if r:
                    result[file][key]['info']=line
                    continue
                if ":" in line:
                    l = line.split(":")
                    l2 = [(None, l[0])]
                    l2.extend([ i.split() for i in l[1:-1]])
                    l2.append((l[-1],None))
                    for i in range(len(l2)-1):
                        result[file][key][l2[i][1]]=l2[i+1][0]
    return result
                    
def transfer_result(result):
    ret = od()
    for k,v in result.items():
        for k2,v2 in v.items():
           if k2 not in ret:
              ret[k2]=od()
           ret[k2][k]=v2
    for k,v in ret.items():
        for k2, v2 in v.items():
            if 'ops/sec' in v2:
                v['ops/sec-total']=v.get('ops/sec-total',0)+float(v2['ops/sec'])
            if 'bytes/sec' in v2:
                v['bytes/sec-total']=v.get('bytes/sec-total',0)+float(v2['bytes/sec'])
        v['bytes/sec-total']="%sM/s"%(v['bytes/sec-total']/1048576)
    return ret
                
def print_pretty(result):
    transferd = transfer_result(result)
    #print " "*20,
    #for f in result:
    #    print "%10s"%os.path.basename(f)[-5:],
    for case,v in transferd.items():
        print "%s-%s: %s"%(case, 'ops/sec-total', transferd[case]['ops/sec-total'])
        print "%s-%s: %s"%(case, 'bytes/sec-total', transferd[case]['bytes/sec-total'])
        


def main():
    files = os.listdir(sys.argv[1])
    files = [os.path.join(sys.argv[1], file) for file in files]
    result = parse(files)
    print_pretty(result)
    return 0


if __name__ == "__main__":
    sys.exit(main())




