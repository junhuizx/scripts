#!/usr/bin/env python
"""

Use this script to configuring multi-region openstack.
It's needed two regions first, and they have same password.

author: zhang, junhui
date: 2016.09.21

"""

import os
import sys
import argparse
import re
import json
import functools
import ConfigParser


KEYSTONE_RC_CMD = "%s"
DRY_RUN = False
IP_PATTERN = re.compile(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}')
KEYSTONE_IP = "localhost"
DASHBOARD_PATH = "/usr/share/openstack-dashboard"


def get_default_ip():
    s = os.popen("ifconfig | grep -w inet | awk '{print $2}'").read().strip()
    ips = re.findall(IP_PATTERN, s)
    return ips[0]


def is_local(ip):
    """if ip is localhost"""
    return os.system("ifconfig | grep %s > /dev/null" % ip) == 0


def system(cmd):
    if DRY_RUN:
        print("dry run: %s" % cmd)
        return 0
    else:
        print("run cmd: %s" % cmd)
        return os.system(cmd)


def ssh_cmd(cmd, host=None):
    """generate a ssh command.
       cmd is a command str be execed in remote host
       host: two types: tuple:  (username, ip)
                        string: username@ip
    """
    user, host = host if isinstance(host, (list, tuple)) else (None, host)
    host = "%s@%s" % (user, host) if host and user else host
    ssh = 'ssh "%s" ' % host if host else ""
    ret = '%s "%s"' % (ssh, cmd) if ssh else cmd
    return ret


def restart_all_openstack_service(host=None):
    # list_cmd = "systemctl -a | grep -E 'openstack|httpd|neutron'"
    # system_services = os.popen(ssh_cmd(list_cmd, host)).read().splitlines()
    # system_services = [x.split()[0] for x in system_services]
    # for service in system_services:
    #     system(ssh_cmd("systemctl restart %s" % service))
    for service in ["httpd.service", "openstack*service", "neutron*service"]:
        system(ssh_cmd("systemctl restart %s" % service))


def parse_opt():
    conf = ConfigParser.ConfigParser()
    parser = argparse.ArgumentParser(description="Setup multi-regions.")
    parser.add_argument('-f', '--config-file', dest="config_file",
                        help="config file")
    # parser.add_argument("-i", "--ip", dest="ip",
    #                     default=get_default_ip(),
    #                     help="host ip")
    # parser.add_argument("-a", "--answer-file", dest="answer_file",
    #                     default="answer-file.txt",
    #                     help="answer file of local host.")
    # parser.add_argument("-r", "--remote", dest="remote",
    #                     required=True,
    #                     help="the other region's controller, "
    #                          "use user@ip format")
    # parser.add_argument("-e", "--remote-answer-file", dest="remote_answer_file",
    #                     default="answer-file.txt",
    #                     help="answer file of remote host.")
    # parser.add_argument("-k", "--keystone-rc", dest="keystone_rc",
    #                     default="source keystonerc_admin",
    #                     help="source keystonerc_admin command, if in the " +
    #                          'devstack enviroment, use "source openrc admin"')
    parser.add_argument("-d", "--dry-run", dest="dry_run",
                        action="store_true",
                        help="answer file of remote host.")
    # parser.add_argument("--dashboard-path", dest="dashboard_path",
    #                     default=DASHBOARD_PATH,
    #                     help="dashboard path of your horizon")
    # parser.add_argument("-l", "--local-region-hosts", dest="local_region_hosts",
    #                     action="append", default=[],
    #                     help="local region hosts: other hosts need change "
    #                          "region settings, if have use -l [ip] -l [ip]")
    # parser.add_argument("-m", "--remote-region-hosts",
    #                     dest="remote_region_hosts",
    #                     action="append", default=[],
    #                     help="remote region hosts: other hosts need change "
    #                          "region settings, if have use -m [ip] -m [ip]")
    args = parser.parse_args()
    if args.config_file:
        conf.read(args.config_file)
    global KEYSTONE_RC_CMD, DRY_RUN, KEYSTONE_IP, DASHBOARD_PATH
    KEYSTONE_RC_CMD = conf.get("global", "openstack_admin_source_cmd")
    DRY_RUN = args.dry_run
    KEYSTONE_IP = conf.get("global", "keystone_ip")
    DASHBOARD_PATH = conf.get("global", "dashboard_path")
    if not conf.get("global", "keystone_ip").strip():
        conf.set("global", "keystone_ip", conf.get("global",
                                                   "controller_virtual_ip"))
    if not conf.get("global", "remote_keystone_ip").strip():
        conf.set("global", "remote_keystone_ip",
                 conf.get("global", "remote_controller_virtual_ip"))
    return conf


def get_list_gener(list_type, args=""):
    def get_(host=None):
        cmd = "%s; openstack %s list -f json %s" % \
              (KEYSTONE_RC_CMD, list_type, args)
        cmd = ssh_cmd(cmd, host)
        print cmd
        return json.load(os.popen(cmd))
    get_.func_name = "get_%s_list" % list_type.replace(" ", "_")
    return get_


get_region_list = get_list_gener("region")
get_service_list = get_list_gener("service", "--long")
get_endpoint_list = get_list_gener("endpoint")
get_hypervisor_list = get_list_gener("hypervisor")


def get_compute_nodes(host=None):
    ssh = 'ssh "%s" ' % host if host else ""
    cmd = r'%s "mysql -uroot --batch -s -e \"select host, host_ip, deleted '\
          r'from nova.compute_nodes;\""' % ssh
    print cmd
    hosts = os.popen(cmd).read().splitlines()
    hosts = [l.split('\t') for l in hosts]
    return hosts


def add_wraper(add_type, name):
    def _wraper(func):
        @functools.wraps(func)
        def add_(keystone_ip, add_types, *args, **kwargs):
            print("Add %s ..." % add_type)
            keystone_host = "root@" + keystone_ip
            names = [name] if isinstance(name, basestring) else name
            get_list_func = globals()["get_%s_list" %
                                      add_type.replace(" ", "_")]
            existences = [[x[y] for y in names] for x in
                          get_list_func(keystone_host)]
            for each in add_types:
                if [each[y] for y in names] in existences:
                    continue
                print("add %s: %s" % (add_type,
                                      each[name] if len(names) == 1 else
                                      [each[y] for y in names]))
                cmd = func(each, *args, **kwargs)
                # FIXME: user need run this script in regionOne's keystone node.
                # if not is_local(keystone_ip):
                #     pass
                assert system(cmd) == 0, "add %s %s failed." % (add_type,
                                                                each[name])
        return add_
    return _wraper


@add_wraper("region", u'Region')
def add_regions(region):
    cmd = "%s && openstack region create %s %s %s" % \
          (KEYSTONE_RC_CMD, region[u'Region'],
           "--parent-region %s" % region[u'Parent Region']
           if region[u'Parent Region'] else "",
           "--description %s" % region[u'Description']
           if region[u'Description'] else "")
    return cmd


@add_wraper("service", u'Type')
def add_services(service):
    cmd = "%s && openstack service create %s %s %s %s" % \
          (KEYSTONE_RC_CMD, service[u'Type'],
           "--name %s" % service[u'Name'] if service[u'Name'] else "",
           "--description %s" % service[u'Description']
           if service[u'Description'] else "",
           "--enable" if service[u"Enabled"] else "--disable"
           )
    return cmd


@add_wraper("endpoint", (u'Region', u'Service Name', u'Interface'))
def add_endpoints(endpoint, conf):
    if endpoint[u"Service Type"] == u'identity':
        keystone_ip = conf.get("global", 'keystone_ip').strip()
        endpoint[u'URL'] = re.sub(IP_PATTERN, keystone_ip, endpoint[u'URL'])
    if '127.0.0.1' in endpoint[u'URL']:
        endpoint[u'URL'].replace('127.0.0.1', conf.get("global",
                                 'remote_controller_virtual_ip'))
    cmd = "%s && openstack endpoint create %s %s \"%s\" %s %s" % \
          (KEYSTONE_RC_CMD, endpoint[u'Service Type'],
           endpoint[u'Interface'], endpoint[u'URL'],
           "--region %s" % endpoint[u'Region'],
           "--enable" if endpoint[u'Enabled'] else "--disable")
    return cmd


def modify_session_engine(conf):
    print ("modify session engine...")
    dashboard_path = conf.get("global", "dashboard_path").strip()
    settings_file = "%s/openstack_dashboard/local/local_settings.py" % \
                    dashboard_path
    controller_hosts = conf.get("global", "controller_hosts").strip()
    controller_hosts = [x.strip() for x in controller_hosts.split(",")] if \
        controller_hosts else [conf.get("global",
                                        "controller_virtual_ip").strip()]
    for ip in controller_hosts:
        host = None if is_local(ip) else "root@" + ip
        if os.system(ssh_cmd("grep SESSION_ENGINE '%s'" % settings_file,
                             host)) != 0:
            memcache = conf.get("global", "memcache").strip()
            if memcache:
                context = """
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
        'LOCATION': '%s',
    }
}
""" % memcache
            else:
                password = os.popen(ssh_cmd('cat ~/.my.cnf | grep password',
                                            host)).\
                    read().splitlines()[0].split("=")[1].replace("'", '')
                context = """
SESSION_ENGINE = 'django.contrib.sessions.backends.cached_db'
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'session',
        'USER': 'root',
        'PASSWORD': '%s',
        'HOST': '',
        'PORT': '3306',
    }
}
""" % password
            if host:
                system('ssh root@%s "cat >> %s " <<EOF \n%sEOF' %
                       (host, settings_file, context))
            else:
                system('cat >> %s <<EOF \n%sEOF' % (settings_file, context))
            if not memcache:
                system(ssh_cmd("mysql -uroot -e 'create database session;'",
                               host))
                system(ssh_cmd("python %s/manage.py migrate" %
                               dashboard_path, host))
            system(ssh_cmd("service httpd restart", host))


def replace_all(path, src, dst, host=None):
    src = src.replace("/", r"\/")
    dst = dst.replace("/", r"\/")
    cmd = "find %s -type f | xargs -n1 sed -i 's/%s/%s/g'" % (path, src, dst)
    return system(ssh_cmd(cmd, host))


def add_config_if_have_not_added(path, pattern, not_add_pattern,
                                 config_lines, host=None):
    pattern = pattern.replace("/", r"\/")
    not_add_pattern = not_add_pattern.replace("/", r"\/")
    config_lines = config_lines if isinstance(config_lines, (list, tuple))\
        else [config_lines]
    assert len(config_lines) >= 1
    context = reduce(lambda x, y: "%si \%s\n" % (x, y), config_lines, "")
    cmd = "find %s -type f | xargs -n1 sed -i  '/%s/{n;/%s/'\!'{%s}}'" %\
          (path, pattern, not_add_pattern, context)
    return system(ssh_cmd(cmd, host))


def modify_keystone_address(host, keystone_ip, vip=None, hosts=None):
    print('modify keystone address: %s' % host)
    endpoint_info = [(x[u"Service Name"], x[u'URL']) for x
                     in get_endpoint_list(host)]
    remote_keystone_ip = None
    ip_address_dict = {}
    for each in endpoint_info:
        ip_address = IP_PATTERN.findall(each[1])
        if len(ip_address) < 1:
            continue
        ip_address = ip_address[0]
        if each[0] == u'keystone':
            remote_keystone_ip = ip_address
        if ip_address == vip and hosts:
            for host in hosts:
                ip_address_dict.setdefault(host, set()).add(each[0])
        else:
            ip_address_dict.setdefault(ip_address, set()).add(each[0])

    for ip, service_set in ip_address_dict.items():
        if ip == "127.0.0.1" or remote_keystone_ip == keystone_ip:
            continue
        print ip
        replace_all("/etc/", remote_keystone_ip + ":5000",
                    keystone_ip + ":5000", ("root", ip))
        replace_all("./keystonerc_admin", remote_keystone_ip + ":5000",
                    keystone_ip + ":5000", ("root", ip))
        replace_all("/etc/", remote_keystone_ip + ":35357",
                    keystone_ip + ":35357", ("root", ip))
        add_config_if_have_not_added("/etc/cinder/cinder.conf",
                                     "#encryption_auth_url",
                                     "encryption_auth_url",
                                     ["encryption_auth_url = http://%s:5000/v3"
                                      % keystone_ip,
                                      "# add by setup_regions.py"],
                                     ("root", ip))
        replace_all("/etc/cinder/cinder.conf",
                    "backup_swift_auth_url *= *http://127.0.0.1:5000/v2.0/",
                    "backup_swift_auth_url = http://%s:5000/v3/" % keystone_ip,
                    ("root", ip))
        restart_all_openstack_service(("root", ip))


def modify_all_keystone_address(conf):
    print('modify all keystone address...')
    keystone_ip = conf.get("global", "keystone_ip").strip()
    remote_keystone_ip = conf.get("global", "remote_keystone_ip").strip()
    remote_keystone_host = "root@" + remote_keystone_ip
    vip = conf.get('global', 'remote_controller_virtual_ip')
    remote_controller_hosts = conf.get("global", "remote_controller_hosts"
                                       ).strip()
    remote_controller_hosts = [x.strip() for x in
                               remote_controller_hosts.split(",")]\
        if remote_controller_hosts else [vip]
    modify_keystone_address(remote_keystone_host, keystone_ip,
                            vip, remote_controller_hosts)


def modify_regions(region, hosts=None):
    for ip in hosts:
        host = "root@%s" % ip if not is_local(ip) else None
        add_config_if_have_not_added("/etc", "#os_region_name *= *<None>",
                                     "^ *os_region_name",
                                     ["os_region_name=%s" % region,
                                      "#add by setup_regions.py"],
                                     host)
        # system(ssh_cmd("find /etc/ -type f | xargs -n1 sed -i  '"
        #                "/#os_region_name *= *<None>/{n;/^ *os_region_name/'\!'"
        #                "{i os_region_name=%s\ni #add by setup_regions.py\n}}'"
        #                % region, host))
        # system(ssh_cmd(r"sed -i '/\[cinder\]/,/\[/{s/#os_region_name=<None>/"
        #                r"os_region_name=%s/g;}' /etc/nova/nova.conf" % region,
        #                host))
        # replace_all("/etc/", "#region_name = <None>",
        #             "region_name = %s" % region, host)
        # replace_all("/etc/", "#os_region_name = <None>",
        #             "os_region_name = %s" % region, host)
        # replace_all("/etc/", "#cinder_os_region_name = <None>",
        #             "cinder_os_region_name = %s" % region, host)
        restart_all_openstack_service(host)


def modify_all_regions(conf):
    if conf.has_section("change_region_settings"):
        regions = conf.get("change_region_settings", "regions").strip()
        regions = [x.strip() for x in regions.split(",")] if regions else []
        for region in regions:
            ip_list = conf.get("change_region_settings", region).strip()
            ip_list = [x.strip() for x in ip_list.split(",")] if ip_list else []
            modify_regions(region, ip_list)


def modify_keystone_endpoint_url_to_v3(conf):
    if conf.get("global", "change_keystone_endpoint_url_to_v3").strip():
        print "modify keystone endpoint url to v3..."
        endpoints = get_endpoint_list()
        for endpoint in endpoints:
            if endpoint[u"Service Name"] == u'keystone':
                if endpoint[u"URL"].endswith("v2.0"):
                    endpoint[u"URL"] = endpoint[u"URL"].replace("v2.0", "v3")
                    cmd = "%s && openstack endpoint set %s --url \"%s\"" % \
                          (KEYSTONE_RC_CMD, endpoint[u'ID'], endpoint[u'URL'])
                    system(cmd)


def get_all_hosts(conf):
    """return all hosts in conf file. host is a IP list"""
    hosts = []
    vip = conf.get('global', 'remote_controller_virtual_ip')
    controller_hosts = conf.get("global", "controller_hosts").strip()
    controller_hosts = [x.strip() for x in controller_hosts.split(",")] \
        if controller_hosts else [vip]
    hosts.extend(controller_hosts)
    rvip = conf.get('global', 'remote_controller_virtual_ip')
    remote_controller_hosts = conf.get("global", "remote_controller_hosts"
                                       ).strip()
    remote_controller_hosts = [x.strip() for x in
                               remote_controller_hosts.split(",")] \
        if remote_controller_hosts else [rvip]
    hosts.extend(remote_controller_hosts)
    if conf.has_section("change_region_settings"):
        regions = conf.get("change_region_settings", "regions").strip()
        regions = [x.strip() for x in regions.split(",")] if regions else []
        for region in regions:
            ip_list = conf.get("change_region_settings", region).strip()
            ip_list = [x.strip() for x in ip_list.split(",")] if ip_list else []
            hosts.extend(ip_list)
    ret = []
    [ret.append(x) for x in hosts if x not in ret]
    return ret


def config_ssh_key(conf):
    password = conf.get('global', 'ssh_password')
    hosts = get_all_hosts(conf)
    ssh_copy_cmd = os.path.join(os.path.dirname(sys.argv[0]), "ssh-copy.sh")
    for host in hosts:
        system("%s %s %s" % (ssh_copy_cmd, host, password))


def reboot_system(conf):
    if conf.get("global", "reboot_system").strip():
        hosts = get_all_hosts(conf)
        has_local = False
        for host in hosts:
            if is_local(host):
                has_local = True
                continue
            system(ssh_cmd("reboot &", ("root", host)))
        if has_local:
            system("sh -c 'echo your system will reboot now;sleep 5;reboot' &")


def main():
    conf = parse_opt()
    config_ssh_key(conf)
    keystone_ip = conf.get("global", "keystone_ip").strip()
    remote_keystone_ip = conf.get("global", "remote_keystone_ip").strip()
    remote_keystone_host = "root@" + remote_keystone_ip
    regions = get_region_list(remote_keystone_host)
    add_regions(keystone_ip, regions)
    services = get_service_list(remote_keystone_host)
    add_services(keystone_ip, services)
    endpoints = get_endpoint_list(remote_keystone_host)
    add_endpoints(keystone_ip, endpoints, conf)
    modify_keystone_endpoint_url_to_v3(conf)
    modify_all_keystone_address(conf)
    modify_session_engine(conf)
    modify_all_regions(conf)
    reboot_system(conf)
    return 0


if __name__ == "__main__":
    sys.exit(main())

