# vm-tools

Collection of scripts for managing VMs. The scripts go back to September 2007
when I first got started with qemu and kvm and wanted a simple means for
starting VMs with a specific setup. vm-tools is a simpler alternative to
libvirt.

Configuring vm-tools
--------------------
After installing the rpm

1. edit /etc/vm-tools.conf

Verify network settings are ok with your installation. Specifically, look at
the MAINBR_ETH setting and make sure it agrees with the  server's primary
connection (see output of 'ip addr show' for which interface has the LAN address).
Update the address for the host-only network, HOSTBR_PREFIX, if desired.

If the VM_DIR, PIDDIR, and SOCKDIR variables are changed be sure to create the
directories.

2. Run the following configure commands in /etc/vm-tools/scripts:

a. configure-dnsmasq.sh -i

This command configures dnsmasq for the host-only bridge. It provides a
simplistic means of using DNS and DHCP with VMs attached to the host-only
bridge.

b. configure-network.sh

This command creates mainbr0 and moves the primary LAN device as a
connection to it

c. configure-sysctl.sh

This command enables IP forwarding and disables reverse path filtering.

d. configure-iptables.sh

This command creates NAT rules so that VM's connected to the host-only
network can get outside access if desired. Specifically, it enables
masquerading in the host and creates port forwarding rules for direct ssh
access to a VM (e.g., ssh -p ${VMID}022 <host> is redirected to port 22 of
VM 1). Save the existing iptables file if desired.

3. run vmtools start script

service vmtools start or /etc/rc.d/init.d/vmtools start

At this point your server is configured and ready to create and run VMs.
VM management

VMs are expected to run as non-root users; users that are to use vm-tools to
run VMs need to belong to the virt group. This group is created the vm-tools
rpm when it is installed. For example, usermod -G virt nobody

Commands to manage a VM are prefixed by vm- and then an action:

    * vm-create - create a VM with specific resources
    * vm-destroy - destroy (remove) a VM
    * vm-clone - make a copy of a VM
    * vm-start - start a VM
    * vm-terminate - stop a VM
    * vm-list - generates a list of created VMs and their runtime status
    * vm-moncmd - send a command to Qemu's monitor

Example

Example workflow with vm-tools.

First, create a VM using the vm-create command:

# vm-create -m 1024 -c 1 -F 20G -i -d 'Ubuntu 14.04.2 desktop' myvm

Successfully created VM myvm

Network data for this VM on the host-only bridge:
IP: 169.254.90.51      MASK: 255.255.255.0  
GW: 169.254.90.1       DNS:  169.254.90.1   

Console access to VM will be available by connecting
a vncviewer to vmware-server:5901

The above command creates a VM with 1GB of memory (-m 1024), one cpu (-c 1), a
20GB harddrive (-F 20G) with default interface (virtio), and a single NIC with
the default device model (virtio) attached to the host-only bridge (-i). The
-d option is the description that will be displayed in the vm-list output and
myvm is the profile name for the VM. The profile name is used in all subsequent
vm-xxxxx commands.


The VM is installed using:

# vm-start -c /path/to/my.iso -b dc myvm

This command boots the VM from the specified CD rom device. Once the
install is complete, you can start the VM using the abbreviated command:

# vm-start myvm

Stopping a VM. Just like a physical server you really, really want to shut down
a VM cleanly. Preferably this means from within the guest. From the host side
you can use the vm-terminate command. By default:

# vm-terminate myvm

Sends the VM an ACPI event equivalent to pressing the power button on a
physical server.

If the OS fails to shutdown cleanly from within the VM and from the acpi
event, then try:

# vm-terminate -r myvm

The -r option attempts to shut down the VM using the qemu monitor. This path
allows qemu-kvm and the vm-start command to clean up resources on the host OS
side. It is equivalent to pulling the plug on a physical server and all the
caveats of such a drastic move apply to a VM. The final terminate option is:

# vm-terminate -f myvm

This uses SIGKILL to force the qemu-kvm process to terminate. This really is
meant to be a last resort.

To see a list of created VMs:

# vm-list

  Id   Profile            Owner        PID     IP Address        Description
  --   ----------------   ----------   -----   ---------------   ----------------
  01   myvm              virt01       -       169.254.90.51      Ubuntu 14.04.2 desktop
