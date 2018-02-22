#!/bin/bash
for i in {1..30}; do
	if [ -S /sys/fs/cgroup/cgmanager/sock ]; then break; fi
	sleep 1
done

exec $SNAP/bin/subutai daemon
