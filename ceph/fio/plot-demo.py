#!/usr/bin/python
# coding: utf-8
import matplotlib.pyplot as plt
import numpy as np
import matplotlib as mpl

mpl.rcParams['font.family'] = 'sans-serif'
mpl.rcParams['font.sans-serif'] = 'NSimSun,Times New Roman'

a = np.loadtxt('./bw.txt', delimiter=',')
print(a)

x,y,z,v = np.loadtxt('./bw.txt', delimiter=',', unpack=True)
#x, y, z = np.loadtxt('./bw.txt', delimiter=',')
plt.plot(x, y, '*', label='Data', color='black')

plt.xlabel('time_ms')
plt.ylabel('throughput_mb')
plt.title('throughput-time grapth')
plt.plot(x,y)
#plt.show()
#plt.legend()
plt.show()