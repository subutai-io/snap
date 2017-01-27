#!/bin/bash
#Include enviroment variables
. $(cd `dirname "${BASH_SOURCE[0]}"` && pwd)/subutai.env

if ! $SUBUTAI_APP_PREFIX/bin/cgproxy --check-master; then
	$SUBUTAI_APP_PREFIX/sbin/cgmanager -m name=systemd 
fi