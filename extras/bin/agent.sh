#!/bin/bash
#if [ "$(grep -c KillMode /etc/systemd/system/snap.subutai-master.agent-service.service)" == "0" ]; then
#   sed -i "s/Type=simple/KillMode=process\nType=simple/g" /etc/systemd/system/snap.subutai-master.agent-service.service
#fi
#systemctl daemon-reload
exec subutai daemon
