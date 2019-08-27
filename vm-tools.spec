Summary: Virtualization scripts for KVM
Name: vm-tools
Version: 27
Release: 1
Group: Applications/Engineering
License: GPL
BuildRoot: %{_tmppath}/%{name}
Vendor: None
Packager: David Ahern
Requires: tunctl, bridge-utils

%description
This package provides a few wrapper scripts for controlling virtual guests.

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf ${RPM_BUILD_ROOT}
exit 0

%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf ${RPM_BUILD_ROOT}
mkdir -p ${RPM_BUILD_ROOT}

pushd ${PROJDIR}
INSTALLBASE=${RPM_BUILD_ROOT}/etc/vm-tools

mkdir -p $INSTALLBASE/vm
mkdir -p $INSTALLBASE/pids
mkdir -p $INSTALLBASE/sockets
mkdir -p $INSTALLBASE/log
chmod 1770 $INSTALLBASE/pids
chmod 1770 $INSTALLBASE/sockets
chmod 1770 $INSTALLBASE/vm
chmod 0750 $INSTALLBASE/log
cp -rp scripts $INSTALLBASE

cp -p config/*.conf ${RPM_BUILD_ROOT}/etc/

mkdir -p ${RPM_BUILD_ROOT}/etc/rc.d/init.d
mv ${INSTALLBASE}/scripts/vmtools.rc ${RPM_BUILD_ROOT}/etc/rc.d/init.d/vmtools

mkdir -p ${RPM_BUILD_ROOT}/etc/profile.d
mv ${INSTALLBASE}/scripts/vmtools.profile ${RPM_BUILD_ROOT}/etc/profile.d/vmtools.sh

mkdir -p ${RPM_BUILD_ROOT}/etc/sudoers.d
mv ${INSTALLBASE}/scripts/sudoers.cnf ${RPM_BUILD_ROOT}/etc/sudoers.d/vmtools
chmod 0440 ${RPM_BUILD_ROOT}/etc/sudoers.d/vmtools

cp -p README ${INSTALLBASE}

(
cd ${RPM_BUILD_ROOT}
find . -type f | sed -e 's,./,/,' | grep -v vmtools.conf
echo "/etc/vm-tools/vm"
echo "/etc/vm-tools/pids"
echo "/etc/vm-tools/sockets"
echo "/etc/vm-tools/log"
) > %{_tmppath}/%{name}.files

popd


%post
. /etc/vm-tools.conf
s=$(awk -F':' '$1 == "'${VM_GRP}'" {print "exists"}' /etc/group)
if [ "$s" != "exists" ]
then
	groupadd $VM_GRP
	[ $? -ne 0 ] && exit 1
fi

chgrp $VM_GRP $PIDDIR $SOCKDIR $VM_DIR

mkdir -p $IMGDIR && chgrp virt $IMGDIR && chmod 1775 $IMGDIR

chkconfig vmtools on

echo -e "\nSee /etc/vm-tools/README for configuring server.\n\n"

grep -q VMHOSTBR $VM_DIR/*.dat
if [ $? -eq 0 ]
then
	echo "Please run convert-vm-nics.sh to convert existing VMs to the new"
	echo "network configuration."
fi

exit 0

%preun
if [ "$1" = "0" ]
then
    service vmtools stop
    chkconfig vmtools off
fi

exit 0


%files -f %{_tmppath}/%{name}.files
%defattr(-,root,root)
%config(noreplace) /etc/vm-tools.conf


%changelog
 * Fri Jun 06 2008 10:42:40  David S. Ahern <dsahern@@gmail.com>
 - initial version
