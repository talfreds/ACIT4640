#!/bin/bash -x
#SERVICE_ACCOUNT=$1
#SERVICE_ACCOUNT_PW=$2
SERVICE_ACCOUNT="todoapp"
SERVICE_ACCOUNT_PW=":k8Ch#h2P!#rU+Vj+"


## This can be used to delete the application files and install a fresh install if the service is stopped 
## and function uncommented

clean_install () {
	sudo userdel -r "$SERVICE_ACCOUNT"
}

install_infra () {
sudo yum install git -y
curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash -
sudo yum install nodejs -y
sudo cp /home/admin/setup/mongodb-org-4.2.repo /etc/yum.repos.d/mongodb-org-4.2.repo
sudo yum install mongodb-org -y
sudo yum install nginx -y
}

create_app_user () {
sudo useradd "$SERVICE_ACCOUNT"
echo ""$SERVICE_ACCOUNT"$SERVICE_ACCOUNT_PW" | sudo chpasswd
sudo chage -E -1 "$SERVICE_ACCOUNT"
}

install_app () {
sudo git clone https://github.com/timoguic/ACIT4640-todo-app.git /home/"$SERVICE_ACCOUNT"/app
sudo chown -R "$SERVICE_ACCOUNT" /home/"$SERVICE_ACCOUNT"/
sudo -H -u todoapp bash -c "cd /home/"$SERVICE_ACCOUNT"/app; npm install"
sudo chmod -R o+rx /home/"$SERVICE_ACCOUNT"/
sudo cp /home/admin/setup/database.js /home/"$SERVICE_ACCOUNT"/app/config/database.js
sudo chown "$SERVICE_ACCOUNT" /home/"$SERVICE_ACCOUNT"/app/config/database.js
}


install_net () {
sudo cp /home/admin/setup/nginx.conf /etc/nginx/nginx.conf
sudo cp /home/admin/setup/todoapp.service /etc/systemd/system/todoapp.service
sudo systemctl enable mongod && sudo systemctl start mongod
sudo systemctl enable nginx && sudo systemctl start nginx
sudo systemctl daemon-reload
}

init_app () {
sudo systemctl enable todoapp
sudo systemctl start todoapp
}

echo "Starting VM Setup..."
#clean_install
install_infra
create_app_user
install_app
install_net
init_app
echo "VM Setup Complete"

