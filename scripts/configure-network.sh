#!/bin/sh

# This script configures the main bridge and its interface

VMTOOLSCONF=${VMTOOLSCONF:=/etc}
. ${VMTOOLSCONF}/vm-tools.conf

if [ -z "$MAINBR_ETH" ]
then
	echo "${0##*/}: MAINBR_ETH not defined" 
	exit 0
fi

cd /etc/sysconfig/network-scripts
if [ $? -ne 0 ]
then
    echo "failed to cd to /etc/sysconfig/network-scripts" >&2
    exit 1
fi

if [ -f ifcfg-${MAINBR} ]
then
    echo "bridge configuration already exists. Not overwriting." >&2
    exit 1
fi

service network stop

#
# create bridge configuration file
#
if [ -f ifcfg-${MAINBR_ETH} ]
then
    mv ifcfg-${MAINBR_ETH} ifcfg-${MAINBR}
    sed -i -e "s/^DEVICE=.*/DEVICE=${MAINBR}/" ifcfg-${MAINBR}
    SHOW_MSG=no

else
    cat > ifcfg-${MAINBR} <<NET
DEVICE=${MAINBR}
ONBOOT=yes
NET

    SHOW_MSG=yes
fi

echo "DELAY=0" >> ifcfg-${MAINBR}


#
# create config file for interface tied to
# main bridge
#
cat > ifcfg-${MAINBR_ETH} <<NET
DEVICE=${MAINBR_ETH}
ONBOOT=yes
BRIDGE=${MAINBR}
NET


if [ "$SHOW_MSG" = "yes" ]
then
cat <<MSG
Created ifcfg-${MAINBR_ETH} and ifcfg-${MAINBR}.

${MAINBR} will start at boot using ${MAINBR_ETH}. No address has been 
configured on ${MAINBR}. To enable DHCP add "BOOTPROTO=dhcp" to
ifcfg-${MAINBR}. To configure static IP address add NETMASK, IPADDR and
GATEWAY variables to ifcfg-${MAINBR}.

MSG
fi

#
# prefer traditional networking scripts to NetworkManager
#
service NetworkManager stop
chkconfig NetworkManager off
chkconfig network on
service network start

exit 0
