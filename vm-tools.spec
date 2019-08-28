Summary: Virtualization scripts for KVM
Name: vm-tools
Version: 27
Release: 1
Group: Applications/Engineering
License: GPL
BuildRoot: %{_tmppath}/%{name}
Vendor: None
Packager: David Ahern
Requires: iproute

%description
This package provides a few wrapper scripts for controlling virtual guests.

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf ${RPM_BUILD_ROOT}
exit 0

%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf ${RPM_BUILD_ROOT}
mkdir -p ${RPM_BUILD_ROOT}

pushd ${PROJDIR}

make BUILDROOT=${RPM_BUILD_ROOT} DESTDIR=/opt install

INSTALLBASE=${RPM_BUILD_ROOT}/opt/vm-tools
chmod 1770 $INSTALLBASE/pids
chmod 1770 $INSTALLBASE/sockets
chmod 1770 $INSTALLBASE/vm
chmod 0750 $INSTALLBASE/log

mkdir -p ${RPM_BUILD_ROOT}/etc/rc.d/init.d
mv ${INSTALLBASE}/bin/vmtools.rc ${RPM_BUILD_ROOT}/etc/rc.d/init.d/vmtools

mkdir -p ${RPM_BUILD_ROOT}/etc/profile.d
mv ${INSTALLBASE}/bin/vmtools.profile ${RPM_BUILD_ROOT}/etc/profile.d/vmtools.sh

mkdir -p ${RPM_BUILD_ROOT}/etc/sudoers.d
mv ${INSTALLBASE}/bin/sudoers.cnf ${RPM_BUILD_ROOT}/etc/sudoers.d/vmtools
chmod 0440 ${RPM_BUILD_ROOT}/etc/sudoers.d/vmtools

cp -p README.md ${INSTALLBASE}

(
cd ${RPM_BUILD_ROOT}
find . -type f | sed -e 's,./,/,' | grep -v vmtools.conf
echo "/opt/vm-tools/vm"
echo "/opt/vm-tools/pids"
echo "/opt/vm-tools/sockets"
echo "/opt/vm-tools/log"
) > %{_tmppath}/%{name}.files

popd


%post
. /opt/vm-tools/vm-tools.conf
s=$(awk -F':' '$1 == "'${VM_GRP}'" {print "exists"}' /etc/group)
if [ "$s" != "exists" ]
then
	groupadd $VM_GRP
	[ $? -ne 0 ] && exit 1
fi

chgrp $VM_GRP $PIDDIR $SOCKDIR $VM_DIR

mkdir -p $IMGDIR && chgrp virt $IMGDIR && chmod 1775 $IMGDIR

echo -e "\nSee /opt/vm-tools/README.md for configuring server.\n\n"

exit 0

%preun
if [ "$1" = "0" ]
then
	# keep this for future additions
	:
fi

exit 0


%files -f %{_tmppath}/%{name}.files
%defattr(-,root,root)
%config(noreplace) /opt/vm-tools/vm-tools.conf


%changelog
 * Wed Aug 28 2019 12:58:44  David S. Ahern <dsahern@@gmail.com>
 - update to remove dependence on legacy networking tools
 - update to use install target in Makefile
 * Fri Jun 06 2008 10:42:40  David S. Ahern <dsahern@@gmail.com>
 - initial version
