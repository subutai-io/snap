#!/bin/bash

# Common logic for new autobuild:
# snapcraft and autobuild is two different components, they are not working with each other (because of complexity of each one)
# if user wants to use his own snap to deploy peer he should run snapcraft first to prepare snap, put snap in the dir with autobuild script
# autobuild script during build first tries to use local snap if it is present, if it is not exist, autobuild just install snap from Store (inet is needed)
# if snap is not exist and Store is not reachable, then we warn user about it with recommendations to install snapcraft and build snap manualy 

function getBranch() {
	local head=$(git rev-parse --abbrev-ref HEAD | grep -iv head)
	if [ "$head" != "" ]; then
		echo "subutai-$head"
	else
		echo "subutai"
	fi
}

function cloneVm() {
	local clone="$1"
        echo "Creating clone"
        vboxmanage clonevm --register --name $clone ubuntu16
        vboxmanage storageattach $clone --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium "`ls -d $PWD/seed.iso`"
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
        while [ "$(sshpass -p "subutai" ssh -o IdentitiesOnly=yes -o ConnectTimeout=1 -o StrictHostKeyChecking=no ubuntu@localhost -p5567 "ls" > /dev/null 2>&1; echo $?)" != "0" ]; do
                sleep 2
        done
}

function stopVM() {
	local vm="$1"
	sshpass -p "subutai" ssh -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -p5567 ubuntu@localhost "sudo sync"
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
        vboxmanage modifyvm $clone --nic3 hostonly
        vboxmanage modifyvm $clone --hostonlyadapter3 vboxnet0
        vboxmanage modifyvm $clone --nic2 nat
        vboxmanage modifyvm $clone --natpf2 "ssh-fwd,tcp,,4567,,22"
        vboxmanage modifyvm $clone --nic1 bridged
        vboxmanage modifyvm $clone --bridgeadapter1 $(/sbin/route -n | grep ^0.0.0.0 | awk '{print $8}' | head -n1)
}

function btrfsInit() {
	echo "Initializing Btrfs disk"
	sshpass -p "subutai" ssh -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -p5567 ubuntu@localhost "sudo /snap/$SUBUTAI/current/bin/btrfsinit /dev/sdb"
}

function localSnap() {
	echo "$(ls ${SUBUTAI}_*.snap 2>/dev/null | tail -1)"
}

function installLocalSnap() {
	local snap="$1"
	echo "Copying local snap to vm"
	sshpass -p "subutai" scp -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -P5567 $snap ubuntu@localhost:/tmp
	echo "Installing local snap"
	sshpass -p "subutai" ssh -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -p5567 ubuntu@localhost "sudo snap install --dangerous --devmode /tmp/$snap"
}

function installSnapFromStore() {
	echo "Running installation command"
	while [ "$(sshpass -p "subutai" ssh -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -p5567 ubuntu@localhost "sudo snap list $SUBUTAI" > /dev/null 2>&1; echo $?)" != "0" ]; do
		sshpass -p "subutai" ssh -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -p5567 ubuntu@localhost "sudo snap install --beta --devmode $SUBUTAI"
		sleep 2
        done
}

function waitForSubutai() {
	echo "$(sshpass -p "subutai" ssh -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -p5567 ubuntu@localhost "sudo snap list $SUBUTAI" > /dev/null 2>&1; echo $?)"
}

function setAutobuildIP() {
	local ip=$(/bin/ip addr show `/sbin/route -n | grep ^0.0.0.0 | awk '{print $8}' | head -n1` | grep -Po 'inet \K[\d.]+')
	echo "Setting loopback IP $ip"
        sshpass -p "subutai" ssh -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -p5567 ubuntu@localhost "sudo bash -c 'echo $ip > /var/snap/$SUBUTAI/current/.ip'"
}

function waitPeerIP() {
        echo "Waiting for Subutai IP address"
	local ip="$(nc -l 48723)"
	timeout 300 echo -e "*******\\nPlease use following command to access your resource host:\\nssh root@$ip\\nor login \"subutai\" with password \"subutai\"\\n*******"
	ssh-keygen -f ~/.ssh/known_hosts -R $ip > /dev/null 2>&1
}

function setPeerVlan() {
	local vlan="$1"
	echo "Setting vlan $vlan"
	sshpass -p "subutai" ssh -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -p5567 ubuntu@localhost "sudo bash -c 'echo $vlan > /var/snap/$SUBUTAI/current/.vlan'"
}

function addSshKey() {
	echo "Adding user key to peer"
	local key="$(ssh-add -L)"
	if [ "$key" != "" ]; then
		sshpass -p "subutai" ssh -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -p5567 ubuntu@localhost "sudo bash -c 'echo "$key" >> /root/.ssh/authorized_keys'"
	fi
}

function setAlias() {
	echo "Setting $SUBUTAI alias"
	sshpass -p "subutai" ssh -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -p5567 ubuntu@localhost "sudo bash -c 'snap alias $SUBUTAI subutai'"
}

function deployPeers() {
        local peer=$(grep PEER "$1" | cut -d"=" -f2)
        local rh=$(grep RH "$1" | cut -d"=" -f2)

        if [ "$peer" == "" ] || [ "$rh" == "" ]; then
                echo "Invalid config"
                exit 1
        fi

        echo "Erecting $peer(x${rh}RH) peer. Please wait"

        local i=0
        while [ $i -lt $peer ]; do
                local j=0
                local vlan=$(shuf -i 1-4096 -n 1)
                while [ $j -lt $rh ]; do
                        local mhip=$($0 -t $vlan | grep "root@" | cut -d"@" -f2)
                        if [ $j -eq 0 ]; then
                                ssh -o StrictHostKeyChecking=no root@$mhip "sudo $SUBUTAI import management"
                                local arr[$i]=$mhip
                        fi
                        let "j=j+1"
                done
                let "i=i+1"
        done

        echo -e "\\nManagement IPs: ${arr[*]}"
	exit 0
}

function exportOvaImg() {
	local vm="$1"
	local dir="../export/ova"
        echo "Exporting OVA image"
        mkdir -p "$dir"
        vboxmanage export $vm -o $dir/${vm}.ova --ovf20
	vboxmanage unregistervm --delete "$vm"
	echo "Exported to $dir/${vm}.ova"
}

function exportBoxImg() {
	local vm="$1"
        local dir="../export/vagrant"
	
	if [ "$(which vagrant)" == "" ]; then
		echo "Vagrant is requried to use this option"
		vboxmanage unregistervm --delete "$vm"
		exit 1
	fi
        echo "Exporting Vagrant box"
        mkdir -p "$dir"
        vagrant init $vm ${vm}.box
        vagrant package --base $vm --output $dir/${vm}.box

        mv -f Vagrantfile .vagrant $dir

        # inject.vagrant parameters into Vagrantfile
        sed -e '/# config.vm.network "public_network"/ {' \
                -e 'r inject.vagrant' -e 'd' -e '}' -i $dir/Vagrantfile
	vboxmanage unregistervm --delete "$vm"
	echo "Exported to $dir/${vm}.box"
}

function readArgs() {
	while [ $# -gt 0 ]; do
		key="$1"

		case $key in
    		-t|--tag)
    			TAG="$2"
    			shift
    		;;
		-e|--export)
			EXPORT="$2"
			shift
		;;
    		-d|--deploy)
                       	CONF="$2"
			shift
            	;;	
		*)
            		echo "Unknown key $key"
    		;;
		esac
		shift
	done
}



####################
###### Main function
####################

EXPORT_DIR="/tmp"
SUBUTAI=$(getBranch)
CLONE="$SUBUTAI-$(date +%s)"

readArgs "$@"

if [ "$CONF" != "" ]; then
	deployPeers "$CONF"
fi

cloneVm "$CLONE"

sshpass -p "subutai" ssh -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -p5567 ubuntu@localhost "sudo snap list $SUBUTAI"
echo $?
sleep 30

while [ $(waitForSubutai) != "0" ]; do
	SNAP=$(localSnap)
	if [ "$SNAP" != "" ]; then
		installLocalSnap "$SNAP"
	else
		installSnapFromStore
	fi
	sleep 2
done

setAlias

if [ "$TAG" != "" ]; then
	setPeerVlan "$TAG"
fi

btrfsInit
addSshKey
setAutobuildIP

### No manipulation inside VM after this step
stopVM "$CLONE"

if [ "$EXPORT" == "ova" ]; then
	exportOvaImg "$CLONE"
	exit 0
elif [ "$EXPORT" == "box" ]; then
	exportBoxImg "$CLONE"
	exit 0 
fi

restoreNet "$CLONE"
startVM "$CLONE"
waitPeerIP


