#!/bin/sh


cat > /etc/sysctl.d/S99-vmtools.conf <<EOF
net.ipv4.ip_forward = 1
net.ipv4.conf.default.rp_filter = 0
EOF

sysctl -p /etc/sysctl.conf

echo "Enabled IP fowarding and disabled reverse-path filtering"

exit 0
