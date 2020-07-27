#!/usr/bin/python
import rados, rbd,sys


bs = 1024**3
#count=int(sys.argv[1])
pool = 'rbd'
datapool = 'ectest'
data = open("/dev/urandom").read(bs)

def create_image(name, bs, count):
    with rados.Rados(conffile="/etc/ceph/ceph.conf") as cluster:
        with cluster.open_ioctx(pool) as ioctx:
            rbd_inst = rbd.RBD()
            rbd_inst.create(ioctx, name, bs*count, data_pool=datapool)
            with rbd.Image(ioctx, name) as image:
                for i in range(count):
                    image.write(data, bs*i)


def create_image_with_small_blocks(name, bs, count):
    with rados.Rados(conffile="/etc/ceph/ceph.conf") as cluster:
        with cluster.open_ioctx(pool) as ioctx:
            rbd_inst = rbd.RBD()
            rbd_inst.create(ioctx, name, bs*count, data_pool=datapool)
            with rbd.Image(ioctx, name) as image:
                for i in range(count):
                    image.write(data, bs*i)


def main():
    global bs, data, count
    name = sys.argv[1]
    count = sys.argv[2]
    if sys.argv[0] == 'small':
        bs = 1024
        count = count * 1024**2
        data = open("/dev/urandom").read(bs)
        create_image_with_small_blocks(name, bs, count)
    else:
        create_image(name, bs, count)

main()
