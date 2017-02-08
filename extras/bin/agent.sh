#!/bin/bash
cp $SNAP/etc/ssh.pem $SNAP_DATA
chmod 600 $SNAP_DATA/ssh.pem

if [ ! -f $SNAP_DATA/agent.gcfg ]; then
	BRANCH=$(echo ${SNAP_NAME#subutai} | tr -d '-')
	sed -e "s|branch = dev|branch = $BRANCH|g" $SNAP/etc/agent.gcfg > $SNAP_DATA/agent.gcfg
	sed -e "s|/snap/subutai/|/snap/$SNAP_NAME/|g" -i $SNAP_DATA/agent.gcfg
fi

while [ ! -S /sys/fs/cgroup/cgmanager/sock ]; do
	sleep 1
done

exec $SNAP/bin/subutai daemon
