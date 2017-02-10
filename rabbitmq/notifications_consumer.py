#!/usr/bin/python
import pika
import sys

def callback(ch, method, properties, body):
    #print (ch, method, properties, body)
    print(" [x] Received %r" % body)
    #print "----"
    ch.basic_ack(delivery_tag = method.delivery_tag)

def main():
    if len(sys.argv) < 2:
        print("usage: python %s rabbmitmq_host [rabbmitmq_port]" % sys.argv[0])
        exit(1)
    host = sys.argv[1]
    port = 5672 if len(sys.argv) < 3 else int(sys.argv[2])
    connection = pika.BlockingConnection(pika.ConnectionParameters(
               host, port))
    channel = connection.channel()
    try:
        channel.queue_declare(queue='notifications.info')
        channel.queue_declare(queue='notifications.error')
        channel.basic_consume(callback,
                          queue='notifications.info',
                          no_ack=False)
        channel.basic_consume(callback,
                          queue='notifications.error',
                          no_ack=False)
        channel.start_consuming()
    finally:
        connection.close()
    exit(0)

main()
