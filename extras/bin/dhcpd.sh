#!/bin/bash
while [ "`/bin/ip addr show | grep -c 10.10.10.254`" == "0" ]; do
        sleep 1
done
	  
$SNAP/bin/dnsmasq -k -p 0 --interface=lxc-br --dhcp-range=10.10.10.10,10.10.10.240,12h --dhcp-leasefile=$SNAP_DATA/dnsmasq.leases --dhcp-option=6,10.10.10.254

