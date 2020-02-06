#!/bin/bash -x


# This is a shortcut function that makes it shorter and more readable
vbmg () { /mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }

NET_NAME="VM4640_Network_Test"
VM_NAME="VM4640_Test"
SSH_PORT="12022"
WEB_PORT="12080"
SSH_PXE_PORT="12222"


# This function will clean the NAT network and the virtual machine
clean_all () {
	vbmg natnetwork remove --netname "$NET_NAME"
	vbmg unregistervm --delete "$VM_NAME" 
}

create_network () {
	vbmg natnetwork add --netname "$NET_NAME" --network "192.168.230.0/24" --enable --dhcp on --port-forward-4 "ssh:tcp:[0.0.0.0]:"$SSH_PORT":[192.168.230.10]:22" --port-forward-4 "http:tcp:[0.0.0.0]:""$WEB_PORT"":[192.168.230.10]:80" --port-forward-4 "ssh_pxe:tcp:[0.0.0.0]:"$SSH_PXE_PORT":[192.168.230.200]:22"
}

get_vm_path () {
SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"
VBOX_FILE=$(vbmg showvminfo "$VM_NAME" | sed -ne "$SED_PROGRAM")
DIR=$(dirname "${VBOX_FILE}")
echo "$DIR"
}

create_vm () {
	vbmg createvm --name "$VM_NAME" --ostype "RedHat_64" --register
	vbmg modifyvm "$VM_NAME" --nic1 natnetwork --nat-network1 "$NET_NAME" --memory 2048 --boot1 disk --boot2 net
	get_vm_path

	vbmg createmedium disk --filename "$DIR"/HD.vdi --size 10000
	vbmg storagectl "$VM_NAME" --name "Sata Controller"  --add "sata"
	vbmg storagectl "$VM_NAME" --name "IDE Controller" --add "ide"
	vbmg storageattach "$VM_NAME" --storagectl "Sata Controller" --type hdd --port 0 --medium "$DIR"/HD.vdi
	vbmg storageattach "$VM_NAME" --storagectl "IDE Controller" --type dvddrive --port 1 --medium emptydrive --device 0

}

echo "Starting script..."
clean_all
create_network
create_vm
vbmg startvm "$VM_NAME" 
echo "DONE!"
