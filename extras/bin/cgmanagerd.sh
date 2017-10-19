#!/bin/bash		
if ! /snap/core/current/sbin/cgproxy --check-master; then		
	/snap/core/current/sbin/cgmanager -m name=systemd
fi
