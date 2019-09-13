#!/bin/bash

set -x

#modprobe kvm
#modprobe vhost-net
#chmod 666 /dev/kvm
#chmod 666 /dev/vhost-net
sudo chgrp kvm /dev/kvm /dev/vhost-net
sudo chmod g+rw /dev/kvm /dev/vhost-net

IP='sudo ip'
IPTABLES='sudo iptables'

NS=$1
[ -z "${NS}" ] && NS=vms

$IP netns list | grep -q ${NS}
if [ $? -ne 0 ]; then
	$IP netns add ${NS}
	$IP netns exec ${NS} ifreload -a

	$IP link del veth-${NS}-ns 2>/dev/null
	$IP link add veth-${NS}-ns type veth peer name veth-out
	$IP link set veth-${NS}-ns up
	$IP link set dev veth-out netns ${NS}

	if [ "${NS}" = "vms" ]; then
		$IP link add br0 type bridge
		$IP addr add  10.1.1.253/24  dev br0
		$IP li sh dev mgmt >/dev/null 2>&1
		if [ $? -eq 0 ]; then
			$IP link set dev br0 vrf mgmt up
		else
			$IP link set dev br0 up
		fi

		$IP link set veth-${NS}-ns master br0

		$IPTABLES -t nat -F
		$IPTABLES -t nat -A PREROUTING -i br0 -j ACCEPT
		$IPTABLES -t nat -A POSTROUTING -s 10.1.1.0/24  -j MASQUERADE

		for n in $(seq 1 9)
		do
			$IPTABLES -t nat -A PREROUTING -p tcp --dport 220$n -j DNAT --to-destination 10.1.1.$n:22
		done
		for n in $(seq 10 20)
		do
			$IPTABLES -t nat -A PREROUTING -p tcp --dport 22$n -j DNAT --to-destination 10.1.1.$n:22
		done
	fi

	$IP netns exec ${NS} ifup -a -v
	ip -netns ${NS} link set veth-out up
	ip -netns ${NS} link set veth-out master br0
	ip -netns ${NS} ro add default via 10.1.1.253

	$IP netns exec ${NS} /usr/sbin/sshd

	#killall radvd
	#mkdir -p /var/run/radvd
	#chown radvd /var/run/radvd/
	#/usr/sbin/radvd -u radvd -p /var/run/radvd/radvd-${NS}-ns.pid
fi
