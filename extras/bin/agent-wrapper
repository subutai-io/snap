#!/bin/bash
#Include enviroment variables
. $(cd `dirname "${BASH_SOURCE[0]}"` && pwd)/subutai.env

while [ ! -S /sys/fs/cgroup/cgmanager/sock ]; do
	sleep 1
done

exec $SUBUTAI_APP_PREFIX/bin/subutai daemon
