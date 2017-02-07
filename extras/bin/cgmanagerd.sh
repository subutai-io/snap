#!/bin/bash
if ! $SNAP/bin/cgproxy --check-master; then
	$SNAP/sbin/cgmanager -m name=systemd
fi
