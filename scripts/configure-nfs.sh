#!/bin/sh

# This script configures NFS to export the directory /exports/ucm to
# VMs running locally.

for r in rpcbind nfs-utils
do
    rpm -q $r >/dev/null 2>&1
    if [ $? -ne 0 ]
    then
        echo "$r rpm is not installed. Please install and re-run this script"
        exit 1
    fi
done

for s in rpcbind rpcidmapd nfs nfslock
do
    chkconfig $s on
    service $s restart
done

echo "NFS successfully configured."
