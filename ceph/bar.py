import sys
import time
class Bar(object):
    def __init__(self, taskname, max=100,
                 fill_char='#', processing_char='>',
                 barlen=50,
                 start_immediately=True):
        count_len = len("%s" % max)
        self.out = '\r{taskname} [{index:%s}/{max}] [{fills}{unfills}] {percent:.2f}%%' % count_len
        self.taskname = taskname
        self.max = max
        self.percent = 0
        self.barlen = barlen
        self.fill_char = fill_char
        self.processing_char = processing_char
        self.fills = ''
        self.unfills = (self.barlen) * ' '
        self.index = 0
        self.step = 1
        if start_immediately:
            self.start()

    def start(self):
        sys.stdout.write(self.out.format(**self.__dict__))
        sys.stdout.flush()

    def __iter__(self):
        #for i in range(1, self.max+1):
        while self.index <= self.max:
            percent = self.index*100.0/self.max
            self.fills = self.fill_char*(int(self.index*self.barlen*1.0/self.max))
            if self.index == self.max:
                self.unfills = ' '*(self.barlen-int(self.index*self.barlen*1.0/self.max))
            else:
                self.unfills = self.processing_char + (' '*(self.barlen-int(self.index*self.barlen*1.0/self.max)-1))
            sys.stdout.write(self.out.format(**self.__dict__))
            sys.stdout.flush()
            if self.index == self.max:
                print("")
                #print "complete!"
            self.index += self.step
            yield percent

    # def next(self, step=1):
    #     self.step = step

def bar(taskname, max=100, fill_char='#', processing_char='>', barlen=50):
    count_len = len("%s" % max)
    out = '\r{taskname} [{index:%s}/{max}] [{fills}{unfills}] {percent:.2f}%%' % count_len
    percent = 0.0
    fills = ''
    unfills = (barlen) * ' '
    index = 0
    step = 1
    sys.stdout.write(out.format(**locals()))
    sys.stdout.flush()
    #step = yield
    while index <= max:
        if index >= max:
            index = max
            unfills = ' ' * (barlen - int(index * barlen * 1.0 / max))
        else:
            unfills = processing_char + (' ' * (barlen - int(index * barlen * 1.0 / max) - 1))
        percent = index * 100.0 / max
        fills = fill_char * (int(index * barlen * 1.0 / max))
        sys.stdout.write(out.format(**locals()))
        sys.stdout.flush()
        if index >= max:
            print("")
            # print "complete!"
        step = yield percent
        step = 1 if step is None else step
        index += step

def processing(taskname):
    count_len = len("%s" % max)
    out = '\r{taskname}: {index}'
    percent = 0.0
    index = 0
    step = 1
    sys.stdout.write(out.format(**locals()))
    sys.stdout.flush()
    while True:
        sys.stdout.write(out.format(**locals()))
        sys.stdout.flush()
        step = yield index
        step = 1 if step is None else step
        index += step

def test_bar():
    max=100
    for i in bar("test_bar", max):
        time.sleep(0.1)
    b=bar("test_bar2", max)
    b.send(None)
    step = 3
    for i in range(int(max/step)+1):
        time.sleep(0.1)
        b.send(step)
        #b.next()
    b.close()


def test_processing():
    max = 100
    b = processing("test_processing")
    b.send(None)
    step = 2
    for i in range(int(max / step)):
        time.sleep(0.1)
        b.send(step)
    b.close()
    print("\ndone")

if __name__ == "__main__":
    test_processing()