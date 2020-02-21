#!/bin/bash -x


scp -r ./setup/ midterm:~/

ssh midterm "bash -s" < ./setup/install_script.sh





