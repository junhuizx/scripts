#!/usr/bin/python
# coding: utf-8

#from __future__ import unicode_literal
import os, sys
import json

def main():
    region=""
    if len(sys.argv) >=2:
        region = sys.argv[1]
    token = os.popen('./get_newtouch_token.sh').read().strip()
    cms_token = "ea3267c81b574c6a8275cc38ef2a1a84"
    hosts_list = os.popen('curl -s "https://cms.console.newtouch.com/api/host/list?pageNo=1&pageSize=100&token=%s"'%token) 
    hosts_list = json.load(hosts_list)
    hosts_list = hosts_list["list"]
    for host in hosts_list:
        if region in host['regionUrl']:
            cms_data_url = host['regionUrl'] + '/cms/data/'
            cmd = """curl -s -i -X POST  -H "Content-Type: application/json" -H "token:%s" -d '{"uuid":["%s"], "count":2}' %s """
            cmd = cmd % (cms_token, host['uuid'], cms_data_url)
            print cmd
            ret = os.popen(cmd).read()
            try:
                print json.loads(ret)
            except:
                print ret

main()

