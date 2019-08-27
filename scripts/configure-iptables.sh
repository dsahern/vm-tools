#!/bin/sh

# Generate a default dnsmasq configuration

VMTOOLSCONF=${VMTOOLSCONF:=/etc}
. ${VMTOOLSCONF}/vm-tools.conf

SYSCFG=/etc/sysconfig/iptables

# save original if we did not create it
head -1 ${SYSCFG} | egrep -q 'vm-tools' 2>/dev/null
if [ $? -ne 0 ]
then
    mv ${SYSCFG} ${SYSCFG}.orig
fi

cat > ${SYSCFG} <<EOF
# Generated by configure-iptables.sh in vm-tools
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -i hostbr1 -j ACCEPT
-A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT
-A INPUT -m state --state NEW -m tcp -p tcp -m multiport --dports 5900:5999 -j ACCEPT
# serial ports
-A INPUT -m state --state NEW -m tcp -p tcp -m multiport --dports 7001:7099 -j ACCEPT
-I FORWARD -m physdev --physdev-is-bridged -j ACCEPT
-A INPUT -j REJECT --reject-with icmp-host-prohibited
COMMIT
*nat
:PREROUTING ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A PREROUTING -i hostbr1 -j ACCEPT

# typical VM NAT'ing
EOF


for i in $(seq 1 30)
do
	n=$(printf "22%02d" $i)
	addr=$((HOSTBR_FIXED_BASE + $i))
	echo "-A PREROUTING -p tcp --dport ${n} -j DNAT --to-destination ${HOSTBR_PREFIX}.${addr}:22"
done >> ${SYSCFG}


cat >> ${SYSCFG} <<EOF
-A POSTROUTING -s ${HOSTBR_NET} -j MASQUERADE
COMMIT
EOF

sed -i -e 's/^IPTABLES_MODULES_UNLOAD=.*/IPTABLES_MODULES_UNLOAD="no"/' \
    /etc/sysconfig/iptables-config
chkconfig iptables on
service iptables restart