#!/bin/sh
# Used to quickly rebuild the snap, install and test it for strict mode
rm -f subutai*.snap
snapcraft clean subutai -s build
snapcraft clean wrappers
./configure
snapcraft
snap remove subutai-master
snap install --dangerous subutai-master*.snap

PLUGS="docker-support firewall-control kernel-module-control kubernetes-support mount-observe network-control openvswitch-support snapd-control system-observe"
for x in $PLUGS; do
	echo $x
	snap connect subutai-master:${x} core:${x}
done

snap interfaces
snap services subutai-master
