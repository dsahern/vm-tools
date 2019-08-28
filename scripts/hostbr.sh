#!/bin/sh

# script to configure, delete and show the status of the host-only
# bridge. Name and network configuration comes from vm-tools.conf

VMTOOLSCONF=${VMTOOLSCONF:=__VMTOOLS_DIR__}
. ${VMTOOLSCONF}/vm-tools.conf
if [ -z "$HOSTBR" ]
then
	echo "HOSTBR is not defined in vm-tools.conf." >&2
	exit 1
fi


function usage
{
	cat <<USE
usage: ${0##*/} [-c|-d|-s]

	-c	create bridge
	-d	delete bridge
	-s	show status of bridge (default action)
USE

	exit 1
}



function config_bridge
{
	if [ -n "$HOSTBR_IP" -a -n "$HOSTBR_MASK" ]
	then
		echo "configuring $HOSTBR with IP $HOSTBR_IP and mask $HOSTBR_MASK"
		ifconfig $HOSTBR $HOSTBR_IP netmask $HOSTBR_MASK up
	else
		echo "bringing up $HOSTBR with no IP"
		ifconfig $HOSTBR up
	fi
	if [ $? -ne 0 ]
	then
		echo "failed to bring-up host-only bridge"
		return 1
	fi

	# NOTE: the mtu setting does not 'stick' until a device is
	#	   connected to it (e.g., tap using brctl addif). nonetheless,
	#	   it feels right to have this here - so at least it is not
	#	   forgotten.
	if [ -n "$HOSTBR_MTU" ]
	then
		ifconfig $HOSTBR mtu $HOSTBR_MTU
		if [ $? -ne 0 ]
		then
			echo "failed to set MTU on host-only bridge"
		fi
	fi
}


################################################################################
# standard linux bridge versions

function create
{
	ifconfig $HOSTBR 1>/dev/null 2>&1
	if [ $? -eq 0 ]
	then
		echo "host-only bridge already configured" >&2
		return 1
	fi

	echo "creating host-only bridge"
	brctl addbr $HOSTBR
	if [ $? -ne 0 ]
	then
		echo "failed to create host-only bridge"
		return 1
	fi

	config_bridge || return 1

	brctl setfd $HOSTBR 0

	return 0
}

function delete
{
	echo "deleting host-only bridge"
	ifconfig $HOSTBR down
	brctl delbr $HOSTBR
}

function status
{
	echo "host-only bridge $HOSTBR:"
	ifconfig $HOSTBR
}


################################################################################
# openswitch versions

function create_ovs
{
	modprobe openvswitch_mod

	SOCK=/usr/local/var/run/openvswitch/db.sock
	ovsdb-server --remote=punix:${SOCK} \
		--remote=db:Open_vSwitch,manager_options \
		--private-key=db:SSL,private_key \
		--certificate=db:SSL,certificate \
		--bootstrap-ca-cert=db:SSL,ca_cert \
		--pidfile --detach

	chmod g+rw ${SOCK}
	chgrp ${VM_GRP} ${SOCK}

	ovs-vswitchd --pidfile --detach

	ovs-vsctl add-br ${HOSTBR} || return 1
	config_bridge || return 1

	return 0
}

function delete_ovs
{
	ovs-vsctl list-ports hostbr1 |
	while read p
	do
		ovs-vsctl del-port ${HOSTBR} ${p}
	done

	ovs-vsctl del-br ${HOSTBR}
}

function status_ovs
{
	ovs-dpctl show ${HOSTBR}
	ovs-ofctl show ${HOSTBR}
}


################################################################################
#
# main

ACTION=
while getopts :cds o
do
	case $o in
		c) [ -n "$ACTION" ] && usage; ACTION=create;;
		d) [ -n "$ACTION" ] && usage; ACTION=delete;;
		s) [ -n "$ACTION" ] && usage; ACTION=status;;
		*) usage;;
	esac
done
shift $(($OPTIND-1))
[ -z "$ACTION" ] && ACTION=status

[ "$USE_OVS" = "yes" ] && ACTION="${ACTION}_ovs"

eval ${ACTION}

# vim: noexpandtab
