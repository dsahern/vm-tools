#!/usr/bin/python

# Written by Paul Marshall, pmarsha2@cisco.com

import socket, sys, getopt

def usage():
	print
	print "qmoncmd.py usage:"
	print "\tpython qmoncmd.py -s socket -c qemucommand"
	print
	print "Run:"
	print "\tpython qmoncmd.py -s socket -c help"
	print
	print "for a list of QEMU commands"
	print

def main():
	commandarg=""
	socketarg=""

	try:
		opts, args = getopt.getopt(sys.argv[1:], "hs:c:")
	except getopt.GetoptError, err:
		print str(err)
		sys.exit(2)

	for arg, val in opts:
		if arg == "-s":
			socketarg = val
		elif arg == "-c":
			commandarg = val + "\n"
		elif arg == "-h":
			usage()
			sys.exit()	

	if (not opts) or (commandarg=="") or (socketarg==""):
		usage()
		sys.exit()

	s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
	s.connect(socketarg)
	while True:
		data = s.recv(4096)
		if "(qemu)" in data:
			bytes = s.send(commandarg)
			while True:
				data = ""
				data = s.recv(4096)
				if data == "":
					s.close()
					sys.exit()
				print data,
				if "(qemu)" in data:
					s.close()
					print
					sys.exit()
	s.close()

main()
