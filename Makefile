shell=/bin/bash

ifeq ($(DESTDIR),)
DESTDIR=/opt
endif
INSTALLBASE=$(DESTDIR)/vm-tools

ifeq ($(BUILDROOT),)
INSTALL_FULL=$(DESTDIR)/vm-tools
else
INSTALL_FULL=$(BUILDROOT)/$(DESTDIR)/vm-tools
endif

#
# Global proj. directory paths
#
# -- rpm spec file expects this path to be available
#
export PROJDIR=$(shell pwd)


#
# RPM build related defines
#

RPMNAME=vm-tools

RPMCMD=/usr/bin/rpmbuild -bb --define '_topdir $(PROJDIR)/rpmbuild' \
       --define '_tmppath $(PROJDIR)/rpmbuild/tmp' \
       --define '_unpackaged_files_terminate_build 0'

rpm:
	@ echo "=======Building $(RPMNAME) RPM=======" ; \
	$(RPMCMD) -bb $(PROJDIR)/$(RPMNAME).spec && \
	echo "=======$(PROJDIR): make rpm is done======="

install:
	mkdir -p $(INSTALL_FULL)/vm $(INSTALL_FULL)/pids $(INSTALL_FULL)/sockets
	mkdir -p $(INSTALL_FULL)/log $(INSTALL_FULL)/bin
	sed -e "s,__VMTOOLS_DIR__,$(INSTALLBASE)," config/vm-tools.conf > $(INSTALL_FULL)/vm-tools.conf
	ls -C1 scripts | while read f; do sed -e "s,__VMTOOLS_DIR__,$(INSTALLBASE)," scripts/$$f > $(INSTALL_FULL)/bin/$$f; done

uninstall:
	rm -rf $(INSTALLBASE)/vm $(INSTALLBASE)/pids $(INSTALLBASE)/sockets
	rm -rf $(INSTALLBASE)/log $(INSTALLBASE)/bin $(INSTALLBASE)/vm-tools.conf
	rmdir $(INSTALLBASE)
