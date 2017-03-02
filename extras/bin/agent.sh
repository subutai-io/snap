#!/bin/bash
cp $SNAP/etc/ssh.pem $SNAP_DATA
chmod 600 $SNAP_DATA/ssh.pem

resize2fs /dev/sda3

while [ ! -S /sys/fs/cgroup/cgmanager/sock ]; do
	sleep 1
done

exec $SNAP/bin/subutai daemon
