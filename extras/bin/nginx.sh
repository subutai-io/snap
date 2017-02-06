#!/bin/bash
#Include enviroment variables
. $(cd `dirname "${BASH_SOURCE[0]}"` && pwd)/subutai.env

mkdir -p /var/snap/$SUBUTAI_APP_TYPE/common/cache/nginx/
mkdir -p $SUBUTAI_DATA_PREFIX/nginx/cache/
mkdir -p $SUBUTAI_DATA_PREFIX/nginx/log/
mkdir -p $SUBUTAI_DATA_PREFIX/nginx/run/
mkdir -p $SUBUTAI_DATA_PREFIX/web/ssl/
while [ $(ping 8.8.8.8 -c1 | grep -c "1 received") -ne 1 ]; do
        sleep 1
done
if [ "$1" == "start" ]; then
        $SUBUTAI_APP_PREFIX/bin/nginx -g "daemon off;"
else
        $SUBUTAI_APP_PREFIX/bin/nginx "$@"
fi
