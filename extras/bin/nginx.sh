#!/bin/bash

mkdir -p $SNAP_DATA/../common/cache/nginx/
mkdir -p $SNAP_DATA/nginx/conf.d/
mkdir -p $SNAP_DATA/nginx/cache/
mkdir -p $SNAP_DATA/nginx/log/
mkdir -p $SNAP_DATA/nginx/run/
mkdir -p $SNAP_DATA/web/ssl/

sed -e "s|/snap/subutai/|/snap/$SNAP_NAME/|g" $SNAP/etc/nginx/proxy.conf > $SNAP_DATA/nginx/conf.d/proxy.conf

while [ "$(/bin/ip route | grep -c ^default)" == 0 ]; do
        sleep 1
done
if [ "$1" == "start" ]; then
        $SNAP/bin/nginx -g "daemon off;"
else
        $SNAP/bin/nginx "$@"
fi
