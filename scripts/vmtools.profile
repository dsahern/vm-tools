#!/bin/sh

# Add path to vm-tools scripts and kvm binaries to path.

VMTOOLSCONF=/etc/vm-tools.conf
. ${VMTOOLSCONF}

if [ -z "$VMTOOLS" ]
then
    echo "VMTOOLS path not set." >&2
    return 1
fi
