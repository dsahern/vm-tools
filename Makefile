shell=/bin/bash

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
