#!/bin/bash -x

SERVICE_NAME="hichat"
SERVICE_ACCOUNT="hichat"
SERVICE_ACCOUNT_PW="disabled"

create_app_user () {

	sudo useradd -m -d /app "$SERVICE_ACCOUNT"
	echo "$SERVICE_ACCOUNT":"$SERVICE_ACCOUNT_PW" | sudo chpasswd
}

install_infra () {
	#yum -y install epel-release
	sudo yum install git -y
	sudo yum install nodejs -y
	sudo yum install nginx -y
	sudo systemctl enable nginx && sudo systemctl start nginx
	sudo cp ~/setup/nginx.conf /etc/nginx/nginx.conf
	sudo cp ~/setup/hichat.service /etc/systemd/system/hichat.service	
}

install_app () {
	sudo rm -r /app
	sudo git clone https://github.com/wayou/HiChat /app
	sudo chown "$SERVICE_ACCOUNT":"$SERVICE_ACCOUNT" /app
	sudo -H -u "$SERVICE_ACCOUNT" bash -c "cd /app; npm install"
	sudo chown -R "$SERVICE_ACCOUNT":"$SERVICE_ACCOUNT" /app
	sudo chmod -R 766 /app
	sudo systemctl enable "$SERVICE_NAME" && sudo systemctl start "$SERVICE_NAME"
	sudo systemctl daemon-reload
}

## start script
create_app_user
install_infra
install_app

## end script

