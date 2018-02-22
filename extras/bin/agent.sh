#!/bin/bash
for i in {1..30}; do
	if [ -S /sys/fs/cgroup/cgmanager/sock ]; then break; fi
	sleep 1
done

snap alias $SNAP_NAME subutai

source $SNAP/etc/bash_completion.tmpl

exec $SNAP/bin/subutai daemon
