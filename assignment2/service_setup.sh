#!/bin/bash -x

START=`date +%s`
# This is a shortcut function that makes it shorter and more readable
vbmg () { /mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }

NET_NAME="NET_4640"
VM_NAME="VM4640_Test"
PXE_NAME="PXE4640"

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

start_servers () {
	vbmg startvm "$PXE_NAME" --type headless

	## this is simply to ensure the pxe server has started before we start our app servers
	while /bin/true; do
		ssh pxe exit
		if [ $? -ne 0 ]; then
			echo "PXE server is not up, sleeping..."
			sleep 2
		else
			break
		fi
	done
	echo "pxe server up, running script"

	## copy our files over to the http server on the pxe server
	scp -r ./setup/ pxe:/home/admin/
	ssh pxe sudo cp -r /home/admin/setup/ /var/www/lighttpd/
	## even though the OS is served by tftp
	
	## replace the kickstart config file with our own
	scp ./setup/ks.cfg pxe:/home/admin/ks.cfg
	ssh pxe sudo cp /home/admin/ks.cfg /var/www/lighttpd/files/ks.cfg
	ssh pxe sudo chmod -R 755 /var/www/lighttpd
	ssh pxe sudo chmod -R 755 /var/www/lighttpd/files
	ssh pxe sudo chmod -R 755 /var/www/lighttpd/setup
	vbmg startvm "$VM_NAME" --type headless
}

shutdown_pxe () {
	while /bin/true; do
		ssh todoapp -o PasswordAuthentication=no exit					                
		if [ $? -ne 0 ]; then
			RECONNECT_TIMEOUT=15
			echo "New application server is not up, sleeping pxe shutdown for $RECONNECT_TIMEOUT..."
			sleep "$RECONNECT_TIMEOUT"
		else
			break
		fi
	done
	echo "Todo Application Server is up, consider reboot when application and database are available"
	ssh pxe sudo shutdown -t 0
	echo "server setup log at: /root/postinstall.log"
	echo "install will be complete when installation log is available at:  /home/admin/install_log.txt"
}



echo "Starting script at $START..."
clean_all
create_network
create_vm
start_servers
shutdown_pxe
END=`date +%s`
RUNTIME=$((END-START))
echo "DONE! Runtime (may not include full app installation): $RUNTIME"
