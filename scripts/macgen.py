#! /usr/bin/python
# copied from:
# http://www.linuxtopia.org/online_books/rhel5/rhel5_xen_virtualization/rhel5_ch19s21.html
# macgen.py script generates a MAC address 
#
import random

# From http://standards.ieee.org/regauth/oui/oui.txt

# vmware: mac = [ 0x00, 0x50, 0x56,
# xen   : mac = [ 0x00, 0x16, 0x3e,

# first bit of first octet should *not* be set - multicast bit
# second bit of first octet should set to indicate a local assignment
mac = [ 0x00, 0x50, 0x56,
random.randint(0x00, 0x7f),
random.randint(0x00, 0xff),
random.randint(0x00, 0xff) ]
print ':'.join(map(lambda x: "%02x" % x, mac))
