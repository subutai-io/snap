#!/bin/bash
#Include enviroment variables
. $(cd `dirname "${BASH_SOURCE[0]}"` && pwd)/subutai.env

cp $SUBUTAI_APP_PREFIX/etc/ssh.pem $SUBUTAI_DATA_PREFIX
chmod 600 $SUBUTAI_DATA_PREFIX/ssh.pem

while [ ! -S /sys/fs/cgroup/cgmanager/sock ]; do
	sleep 1
done

exec $SUBUTAI_APP_PREFIX/bin/subutai daemon
