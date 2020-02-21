#!/bin/bash -x

## Tyler Alfreds - A01026839 - 4640 Midterm

## shortcut for readability and convenience
vbmg () { /mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }


NET_NAME="NETMIDTERM"                                                                                     
VM_ORIG_NAME="MIDTERM4640"
VM_NAME="A01026839"
SSH_PORT="12922"
WEB_PORT="12980"


# This function will clean the NAT network and the virtual machine                                                 

clean_all () {
	vbmg natnetwork remove --netname "$NET_NAME"
	vbmg unregistervm --delete "$VM_NAME"
}

create_network () {
	vbmg natnetwork add --netname "$NET_NAME" --network "192.168.10.0/24" --enable --dhcp off --port-forward-4 "ssh:tcp:[0.0.0.0]:"$SSH_PORT":[192.168.10.10]:22" --port-forward-4 "http:tcp:[0.0.0.0]:""$WEB_PORT"":[192.168.10.10]:80" 
}

rename_vm () {
	vbmg modifyvm "$VM_ORIG_NAME" --name "$VM_NAME"
}

connect_network () {
	vbmg modifyvm "$VM_NAME" --nat-network1 "$NET_NAME"
}

start_and_confirm () {
	vbmg startvm "$VM_NAME"
	        while /bin/true; do
			ssh midterm exit
			if [ $? -ne 0 ]; then
				echo "App server is not up, sleeping..."
				sleep 2
			else
				break
			fi
		done
	echo "App server up, complete"		
}

## run the program

create_network
rename_vm
connect_network
start_and_confirm

## end of script
echo "Script Complete"

