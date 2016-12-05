#!/usr/bin/env python
# coding: utf-8
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
SOURCE_CMD = "source ~/keystonerc_admin"


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
       host: two types: tuple:  (username, ip
                        string: username@ip
    """
    user, host = host if isinstance(host, (list, tuple)) else (None, host)
    host = "%s@%s" % (user, host) if host and user else host
    ssh = 'ssh "%s" ' % host if host else ""
    ret = "%s '%s'" % (ssh, cmd.replace("'", r"'\''")) if ssh else cmd
    return ret


def restart_all_openstack_service(host=None):
    print "restart all openstack service:", host
    list_cmd = "systemctl -a | grep -E 'openstack|httpd|neutron'"
    system_services = os.popen(ssh_cmd(list_cmd, host)).read().splitlines()
    system_services = [x.split()[1] if x.split()[0] == "●" else x.split()[0]
                       for x in system_services]
    for service in system_services:
        system(ssh_cmd("systemctl restart %s" % service, host))
    # for service in ["httpd.service", "openstack*service", "neutron*service"]:
    #     system(ssh_cmd("systemctl restart %s" % service, host))


def parse_opt():
    conf = ConfigParser.ConfigParser()
    parser = argparse.ArgumentParser(description="Setup multi-regions.")
    parser.add_argument('-f', '--config-file', dest="config_file",
                        help="config file")
    parser.add_argument("-d", "--dry-run", dest="dry_run",
                        action="store_true",
                        help="answer file of remote host.")
    args = parser.parse_args()
    if args.config_file:
        conf.read(args.config_file)
    global KEYSTONE_RC_CMD, DRY_RUN, KEYSTONE_IP, DASHBOARD_PATH, SOURCE_CMD
    KEYSTONE_RC_CMD = conf.get("global", "openstack_admin_source_cmd")
    DRY_RUN = args.dry_run
    KEYSTONE_IP = conf.get("global", "keystone_ip")
    DASHBOARD_PATH = conf.get("global", "dashboard_path")
    SOURCE_CMD = conf.get("global", "openstack_admin_source_cmd")
    if not conf.get("global", "keystone_ip").strip():
        conf.set("global", "keystone_ip", conf.get("global",
                                                   "controller_virtual_ip"))
    if not conf.get("global", "remote_keystone_ip").strip():
        conf.set("global", "remote_keystone_ip",
                 conf.get("global", "remote_controller_virtual_ip"))
    conf.juno = conf.get("global", "juno").strip()
    return conf


def get_list_gener(list_type, args=""):
    def get_(host=None):
        cmd = "%s; /tmp/openstack %s list -f json %s" % \
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
            #keystone_host = "root@" + keystone_ip
            names = [name] if isinstance(name, basestring) else name
            get_list_func = globals()["get_%s_list" %
                                      add_type.replace(" ", "_")]
            existences = [[x[y] for y in names] for x in
                          get_list_func()]
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
    cmd = "%s && /tmp/openstack region create %s %s %s" % \
          (KEYSTONE_RC_CMD, region[u'Region'],
           "--parent-region %s" % region[u'Parent Region']
           if region[u'Parent Region'] else "",
           "--description %s" % region[u'Description']
           if region[u'Description'] else "")
    return cmd


@add_wraper("service", u'Type')
def add_services(service):
    cmd = "%s && /tmp/openstack service create %s %s %s %s" % \
          (KEYSTONE_RC_CMD, service[u'Type'],
           "--name %s" % service[u'Name'] if service[u'Name'] else "",
           "--description '%s'" % service[u'Description']
           if service[u'Description'] else "",
           "--enable" if u"Enabled" not in service or service[u"Enabled"]
           else "--disable"
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
    if 'localhost' in endpoint[u'URL']:
        endpoint[u'URL'].replace('localhost', conf.get("global",
                                 'remote_controller_virtual_ip'))
    cmd = "%s && /tmp/openstack endpoint create %s %s \"%s\" %s %s" % \
          (KEYSTONE_RC_CMD, endpoint[u'Service Name'],
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
    memcache = conf.get("global", "memcache").strip()
    mysql = conf.get("global", "mysql").strip().split(":")
    mysql = mysql if mysql else [""]
    mysql_ip, mysql_port = mysql[:2] if len(mysql) >= 2 \
        else (mysql[0], "")
    user, passwd = "session", "session"
    if not memcache:
        mysql_host = mysql_ip if mysql_ip else None
        system(ssh_cmd("mysql -u root -e 'create database session;'",
                       mysql_host))
        system(ssh_cmd("mysql -u root -e 'CREATE USER \"%s\"@\"%%\""
                       " IDENTIFIED BY \"%s\";'" % (user, passwd),
                       mysql_host))
        system(ssh_cmd("mysql -u root -e 'GRANT ALL ON session.* TO "
                       "\"%s\"@\"%%\";'" % user, mysql_host))
    first = True
    for ip in controller_hosts:
        host = None if is_local(ip) else "root@" + ip
        if os.system(ssh_cmd("grep SESSION_ENGINE '%s'" % settings_file,
                             host)) != 0:
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
                context = """
SESSION_ENGINE = 'django.contrib.sessions.backends.cached_db'
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'session',
        'USER': '%s',
        'PASSWORD': '%s',
        'HOST': '%s',
        'PORT': '%s',
    }
}
""" % (user, passwd, mysql_ip, mysql_port)
            if host:
                system('ssh %s "cat >> %s " <<EOF \n%sEOF' %
                       (host, settings_file, context))
            else:
                system('cat >> %s <<EOF \n%sEOF' % (settings_file, context))
            if first and not memcache:
                print "migrate"
                ret = system(ssh_cmd("python %s/manage.py migrate" %
                                     dashboard_path, host))
                # because some version don't have migrate command, use syncdb
                if ret != 0:
                    print "syncdb"
                    system(ssh_cmd("python %s/manage.py syncdb --noinput" %
                                         dashboard_path, host))
                first = False
            system(ssh_cmd("service httpd restart", host))


def replace_all(path, src, dst, host=None):
    src = src.replace("/", r"\/")
    dst = dst.replace("/", r"\/")
    cmd = "find %s -type f | xargs -n1 sed -i 's/%s/%s/g'" % (path, src, dst)
    # print "Before ssh_cmd:", cmd
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
    # print "Before ssh_cmd:", cmd
    return system(ssh_cmd(cmd, host))


def modify_keystone_address(host, keystone_ip, vip=None, hosts=None,
                            remote_compute_hosts=[], keystone_api_version='v3'):
    print('modify keystone address: %s' % host)
    # get all endpoints in the other region
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
        print ip
        host = ("root", ip)
        add_config_if_have_not_added("/etc/cinder/cinder.conf",
                                     "#encryption_auth_url",
                                     "encryption_auth_url",
                                     ["encryption_auth_url = http://%s:5000/%s"
                                      % (keystone_ip, keystone_api_version),
                                      "# add by setup_regions.py"],
                                     host)
        replace_all("/etc/cinder/cinder.conf",
                    "backup_swift_auth_url *= *http://127.0.0.1:5000/v2.0/",
                    "backup_swift_auth_url = http://%s:5000/%s/" %
                    (keystone_ip, keystone_api_version),
                    host)
        if ip == "127.0.0.1" or remote_keystone_ip == keystone_ip:
            continue
        # Just modify other region's keystone ip address
        replace_all("/etc/", remote_keystone_ip + ":5000",
                    keystone_ip + ":5000", host)
        replace_all("./keystonerc_admin", remote_keystone_ip + ":5000",
                    keystone_ip + ":5000", host)
        replace_all("/etc/", remote_keystone_ip + ":35357",
                    keystone_ip + ":35357", host)
        # In juno, need change all auth_host
        replace_all("/etc/", "auth_host *= *" + remote_keystone_ip,
                    "auth_host=" + keystone_ip, host)
        replace_all("/etc/glance/glance-cache.conf",
                    "^auth_url *= *http://localhost",
                    "auth_url=http://" + keystone_ip, host)
        #restart_all_openstack_service(host)
    for host in remote_compute_hosts:
        host = ("root", host)
        replace_all("/etc/", remote_keystone_ip + ":5000",
                    keystone_ip + ":5000", host)
        replace_all("/etc/", remote_keystone_ip + ":35357",
                    keystone_ip + ":35357", host)
        # In juno, need change all auth_host
        replace_all("/etc/", "auth_host *= *" + remote_keystone_ip,
                    "auth_host=" + keystone_ip, host)


def modify_all_keystone_address(conf):
    print('modify all keystone address...')
    keystone_ip = conf.get("global", "keystone_ip").strip()
    #remote_keystone_ip = conf.get("global", "remote_keystone_ip").strip()
    #remote_keystone_host = "root@" + remote_keystone_ip
    vip = conf.get('global', 'controller_virtual_ip')
    controller_hosts = conf.get("global", "controller_hosts").strip()
    controller_hosts = [x.strip() for x in controller_hosts.split(",")] \
        if controller_hosts else [vip]
    rvip = conf.get('global', 'remote_controller_virtual_ip')
    remote_controller_hosts = conf.get("global", "remote_controller_hosts"
                                       ).strip()
    remote_controller_hosts = [x.strip() for x in
                               remote_controller_hosts.split(",")]\
        if remote_controller_hosts else [rvip]
    remote_compute_hosts = conf.get("global", "remote_compute_hosts").strip()
    remote_compute_hosts = remote_compute_hosts.split(",") if \
        remote_compute_hosts else []
    keystone_api_version = conf.get("global", "keystone_api_version").strip()
    modify_keystone_address(['root', remote_controller_hosts[0]], keystone_ip,
                            rvip, remote_controller_hosts, remote_compute_hosts,
                            keystone_api_version)
    for host in controller_hosts:
        host = ['root', host]
        add_config_if_have_not_added("/etc/cinder/cinder.conf",
                                     "#encryption_auth_url",
                                     "encryption_auth_url",
                                     ["encryption_auth_url = http://%s:5000/%s"
                                      % (keystone_ip, keystone_api_version),
                                      "# add by setup_regions.py"],
                                     host)
        replace_all("/etc/cinder/cinder.conf",
                    "backup_swift_auth_url *= *http://127.0.0.1:5000/v2.0/",
                    "backup_swift_auth_url = http://%s:5000/%s/" %
                    (keystone_ip, keystone_api_version),
                    host)
        #restart_all_openstack_service(host)


def is_local_region(region):
    cmd = "%s; echo $OS_REGION_NAME | grep -w '%s'" % (SOURCE_CMD, region)
    return os.system(cmd) == 0


def modify_regions(region, hosts=None):
    for ip in hosts:
        host = "root@%s" % ip if not is_local(ip) else None
        add_config_if_have_not_added("/etc", "# *os_region_name *= *<None>",
                                     "^ *os_region_name",
                                     ["os_region_name=%s" % region,
                                      "#add by setup_regions.py"],
                                     host)
        # In juno, dashboard can't get network list wehn
        # modify RegionOne's ml2_conf_arista.ini file
        # if not is_local_region(region):
        add_config_if_have_not_added("/etc/neutron/plugins/ml2",
                                     "# *Example: *region_name *=",
                                     "^ *region_name",
                                     ["region_name=%s" % region,
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


def modify_all_regions(conf):
    if conf.has_section("change_region_settings"):
        regions = conf.get("change_region_settings", "regions").strip()
        regions = [x.strip() for x in regions.split(",")] if regions else []
        for region in regions:
            ip_list = conf.get("change_region_settings", region).strip()
            ip_list = [x.strip() for x in ip_list.split(",")] if ip_list else []
            modify_regions(region, ip_list)


def modify_keystone_endpoint_url_to_v3(conf):
    v3 = conf.get("global", "change_keystone_endpoint_url_to_v3").strip()
    if v3.lower() == "true":
        regions = []
    else:
        regions = [x.strip() for x in v3.split(",")]
    if v3:
        print "modify keystone endpoint url to v3..."
        endpoints = get_endpoint_list()
        for endpoint in endpoints:
            if endpoint[u"Service Name"] == u'keystone':
                if endpoint[u"URL"].endswith("v2.0"):
                    if not regions or endpoint[u'Region'] in regions:
                        endpoint[u"URL"] = endpoint[u"URL"].replace("v2.0",
                                                                    "v3")
                        cmd = "%s && /tmp/openstack endpoint set %s --url \"%s\"" % \
                            (KEYSTONE_RC_CMD, endpoint[u'ID'], endpoint[u'URL'])
                        system(cmd)


def modify_vif_plugging_is_fatal(conf):
    """In juno, if didn't chang this setting, It can't create an instance successfully."""
    juno = conf.get('global', 'juno').strip()
    if juno:
        rvip = conf.get('global', 'remote_controller_virtual_ip')
        remote_controller_hosts = conf.get("global", "remote_controller_hosts"
                                           ).strip()
        remote_controller_hosts = [x.strip() for x in
                                   remote_controller_hosts.split(",")] \
            if remote_controller_hosts else [rvip]
        remote_compute_hosts = conf.get("global", "remote_compute_hosts").strip()
        remote_compute_hosts = remote_compute_hosts.split(",") if \
            remote_compute_hosts else []
        hosts = remote_controller_hosts + remote_compute_hosts
        for host in hosts:
            replace_all("/etc/nova/nova.conf", "^vif_plugging_is_fatal.*", "vif_plugging_is_fatal=False",
                        host)
            replace_all("/etc/nova/nova.conf", "^vif_plugging_timeout.*", "vif_plugging_timeout=0",
                        host)


def get_all_openstack_hosts(conf):
    """return all hosts in conf file. host is a IP list"""
    hosts = []
    vip = conf.get('global', 'controller_virtual_ip').strip()
    controller_hosts = conf.get("global", "controller_hosts").strip()
    controller_hosts = [x.strip() for x in controller_hosts.split(",")] \
        if controller_hosts else [vip]
    hosts.extend(controller_hosts)
    rvip = conf.get('global', 'remote_controller_virtual_ip').strip()
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


def get_all_hosts(conf):
    hosts = get_all_openstack_hosts(conf)
    mysql = conf.get("global", "mysql").strip()
    if mysql:
        hosts.append(mysql.split(":")[0])
    return hosts


def config_ssh_key(conf):
    password = conf.get('global', 'ssh_password')
    hosts = get_all_hosts(conf)
    ssh_copy_cmd = os.path.join(os.path.dirname(sys.argv[0]), "ssh-copy.sh")
    for host in hosts:
        os.system("%s %s %s" % (ssh_copy_cmd, host, password))


def setup_openstack(conf):
    base_path = os.path.dirname(__file__)
    hosts = get_all_hosts(conf)
    print hosts
    cmd = "ln -s /tmp/openstack.py /tmp/openstack" if conf.juno\
          else "if which openstack; then ln -s `which openstack` " \
               "/tmp/openstack; else " \
               "ln -s /tmp/openstack.py /tmp/openstack; fi"
    for host in hosts:
        scp_cmd = "scp %s/openstack %s:/tmp/openstack.py" % (base_path, host)
        print(scp_cmd)
        os.system(scp_cmd)
        ln_cmd = ssh_cmd(cmd, host)
        print(ln_cmd)
        os.system(ln_cmd)


def teardown_openstack(conf):
    hosts = get_all_hosts(conf)
    cmd = "rm -f /tmp/openstack /tmp/openstack.py"
    for host in hosts:
        rm_cmd = ssh_cmd(cmd, host)
        print (rm_cmd)
        os.system(rm_cmd)


def reboot_system(conf):
    hosts = get_all_openstack_hosts(conf)
    if conf.get("global", "reboot_system").strip():
        has_local = False
        for host in hosts:
            if is_local(host):
                has_local = True
                continue
            system(ssh_cmd("reboot &", ("root", host)))
        if has_local:
            system("sh -c 'echo your system will reboot now;sleep 5;reboot' &")
    else:
        for host in hosts:
            restart_all_openstack_service(host)


def main():
    conf = parse_opt()
    config_ssh_key(conf)
    setup_openstack(conf)
    try:
        keystone_ip = conf.get("global", "keystone_ip").strip()
        remote_keystone_ip = conf.get("global", "remote_keystone_ip").strip()
        remote_controller_hosts = conf.get("global", "remote_controller_hosts"
                                           ).strip()
        remote_controller_host = remote_controller_hosts.split(",")[0]\
            if remote_controller_hosts else remote_keystone_ip
        remote_controller_host = ("root", remote_controller_host)
        regions = get_region_list(remote_controller_host)
        add_regions(keystone_ip, regions)
        services = get_service_list(remote_controller_host)
        add_services(keystone_ip, services)
        endpoints = get_endpoint_list(remote_controller_host)
        add_endpoints(keystone_ip, endpoints, conf)
        modify_keystone_endpoint_url_to_v3(conf)
        modify_all_keystone_address(conf)
        modify_session_engine(conf)
        modify_all_regions(conf)
        modify_vif_plugging_is_fatal(conf)
    finally:
        teardown_openstack(conf)
    reboot_system(conf)
    return 0


if __name__ == "__main__":
    sys.exit(main())

