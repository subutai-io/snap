#!/bin/bash
while [ "`ifconfig | grep '10.10.10.254' | wc -l`" -eq "0" ]; do
        sleep 1
done
	  
$SNAP/bin/dnsmasq -k -p 0 --interface=nat --dhcp-range=10.10.10.10,10.10.0.240,12h --dhcp-leasefile=$SNAP_DATA/dnsmasq.leases --dhcp-option=6,10.10.10.254

