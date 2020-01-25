#!/bin/bash -x

#Warning: Script will overrwrite existing configuration files based off the files configured in the setup directory

## copy our setup directory
scp -r ./setup todoapp:/home/admin

## this sets the username of the service account used by the todoapp service
## SERVICE_ACCOUNT must match the user account in configuration files found in ./setup directory
SERVICE_ACCOUNT="todoapp"
SERVICE_ACCOUNT_PW=":k8Ch#h2P!#rU+Vj+"

ssh todoapp "bash -s" < ./setup/install_script.sh "$SERVICE_ACCOUNT" "$SERVICE_ACCOUNT_PW"
