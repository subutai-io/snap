#!/bin/bash

# Common logic for new autobuild:
# snapcraft and autobuild is two different components, they are not working with each other (because of complexity of each one)
# if user wants to use his own snap to deploy peer he should run snapcraft first to prepare snap, put snap in the dir with autobuild script
# autobuild script during build first tries to use local snap if it is present, if it is not exist, autobuild just install snap from Store (inet is needed)
# if snap is not exist and Store is not reachable, then we warn user about it with recommendations to install snapcraft and build snap manualy 


function cloneVm() {
	local clone="$1"
        echo "Creating clone"
        vboxmanage clonevm --register --name $clone core
        vboxmanage modifyvm $clone --nic1 none
        vboxmanage modifyvm $clone --nic2 none
        vboxmanage modifyvm $clone --nic3 none
        vboxmanage modifyvm $clone --nic4 nat
        vboxmanage modifyvm $clone --cableconnected4 on
        vboxmanage modifyvm $clone --natpf4 "ssh-fwd,tcp,,5567,,22"
        vboxmanage modifyvm $clone --rtcuseutc on
	startVM $clone

        echo "Cleaning keys"
        ssh-keygen -f ~/.ssh/known_hosts -R [localhost]:5567

        echo "Waiting for ssh"
        while [ "$(sshpass -p "ubuntai" ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no subutai@localhost -p5567 "ls" > /dev/null 2>&1; echo $?)" != "0" ]; do
                sleep 2
        done
}

function stopVM() {
	local vm="$1"
	sshpass -p "ubuntai" ssh -o StrictHostKeyChecking=no -p5567 subutai@localhost "sudo sync"
        echo "Shutting down vm"
        vboxmanage controlvm $vm poweroff
}

function startVM() {
	local vm="$1"
	echo "Starting vm"
        vboxmanage startvm --type headless $vm
}

function restoreNet() {
	local clone="$1"
        echo "Restoring network"
        sleep 3

        if [ "$(vboxmanage list hostonlyifs | grep -c vboxnet0)" == "0" ]; then
                vboxmanage hostonlyif create
        fi
        vboxmanage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1
        if [ "$(vboxmanage list dhcpservers | grep -c vboxnet0)" == "0" ]; then
                vboxmanage dhcpserver add --ifname vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0 --lowerip 192.168.56.100 --upperip 192.168.56.200
        fi
        vboxmanage dhcpserver modify --ifname vboxnet0 --enable

        vboxmanage modifyvm $clone --nic4 none
        #vboxmanage modifyvm $clone --nic3 hostonly
        #vboxmanage modifyvm $clone --hostonlyadapter3 vboxnet0
        #vboxmanage modifyvm $clone --nic2 nat
        #vboxmanage modifyvm $clone --natpf2 "ssh-fwd,tcp,,4567,,22"
        vboxmanage modifyvm $clone --nic1 bridged
        vboxmanage modifyvm $clone --bridgeadapter1 $(/sbin/route -n | grep ^0.0.0.0 | awk '{print $8}')
}

function btrfsInit() {
	echo "Initializing Btrfs disk"
	sshpass -p "ubuntai" ssh -o StrictHostKeyChecking=no -p5567 subutai@localhost "sudo subutai.btrfsinit /dev/sdb"
}

function export_ova() {
	local $clone="$1"
        echo "Exporting OVA image"
        mkdir -p "$EXPORT_DIR/ova"
        vboxmanage export $clone -o $EXPORT_DIR/ova/${clone}.ova --ovf20
}

function export_box() {
        mkdir -p "$EXPORT_DIR/vagrant/"
        local dst="$EXPORT_DIR/vagrant/"
	local clone="$1"

        echo "Exporting Vagrant box"
        vagrant init $clone ${clone}.box
        vagrant package --base $clone --output $dst/${clone}.box

        mv -f Vagrantfile .vagrant $dst

        # inject.vagrant parameters into Vagrantfile
        sed -e '/# config.vm.network "public_network"/ {' \
                -e 'r inject.vagrant' -e 'd' -e '}' -i $dst/Vagrantfile
}

function ifLocalSnapExist() {
	local snap="$(ls subutai*.snap 2>/dev/null | tail -1)"
	echo $snap
}

function installLocalSnap() {
	local snap="$1"
	echo "Copying local snap to vm"
	sshpass -p "ubuntai" scp -o StrictHostKeyChecking=no -P5567 $snap subutai@localhost:~
	echo "Installing local snap"
	sshpass -p "ubuntai" ssh -o StrictHostKeyChecking=no -p5567 subutai@localhost "sudo snap install --dangerous --devmode /home/subutai/$snap"
	while [ "$(sshpass -p "ubuntai" ssh -o StrictHostKeyChecking=no -p5567 subutai@localhost "sudo rm -f /home/subutai/$snap"; echo $?)" != "0" ]; do
		sleep 2
	done
}

function installSnapFromStore() {
	echo "Running installation command"
	sshpass -p "ubuntai" ssh -o StrictHostKeyChecking=no -p5567 subutai@localhost "sudo snap install --beta --devmode subutai"
}

function waitForSubutai() {
	echo "Waiting for subutai installation complete"
	while [ "$(sshpass -p "ubuntai" ssh -o StrictHostKeyChecking=no -p5567 subutai@localhost "sudo snap list subutai" > /dev/null 2>&1; echo $?)" != "0" ]; do
		sleep 2
	done
}

function waitForSnapd() {
	echo "Waiting for Snapd"
	while [ "$(sshpass -p "ubuntai" ssh -o StrictHostKeyChecking=no -p5567 subutai@localhost "sudo snap info subutai" > /dev/null 2>&1; echo $?)" != "0" ]; do
		sleep 2
	done
}

function setAutobuildIP() {
	local ip=$(/bin/ip addr show `/sbin/route -n | grep ^0.0.0.0 | awk '{print $8}'` | grep -Po 'inet \K[\d.]+')
	echo "Setting loopback IP: $ip"
        sshpass -p "ubuntai" ssh -o StrictHostKeyChecking=no -p5567 subutai@localhost "echo $ip > /home/subutai/.ip"
}

function waitPeerIP() {
        echo "Waiting for Subutai IP address"
	local ip="$(nc -l 48723)"
	echo -e "\\nPlease use following command to access your new Subutai:\\nssh subutai@$ip"
	ssh-keygen -f ~/.ssh/known_hosts -R $ip > /dev/null 2>&1
}

#####
### Main function
#####

EXPORT_DIR="/tmp"
CLONE="subutai-16.04-$(date +%s)"

cloneVm "$CLONE"
waitForSnapd
setAutobuildIP

SNAP=$(ifLocalSnapExist)
if [ "$SNAP" != "" ]; then
	installLocalSnap "$SNAP"
else
	installSnapFromStore
fi

waitForSubutai

btrfsInit

stopVM "$CLONE"
restoreNet "$CLONE"
startVM "$CLONE"
waitPeerIP
