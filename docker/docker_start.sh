#!/bin/bash 

# File:	docker_start.sh - startup a container passed in (deploy it if needed).
#
# eg call:	./docker_start.sh  uisdocker1-adviseu-test
#
# Note:	Can easily fail - e.g., starting a stopped container - a port is already used;

# Check the number of arguments...
#
if [ $# -ne 1 ]; then
        echo "$0 requires 1 argument"
	exit
fi

# See if docker exist (is deployed)...
#
sudo docker ps -a | grep -is  $containerID  > /tmp/$$_docker_ps   2>&1
if [ $? -ne 0 ]; then
        sudo docker login -u tulio -p xxxxxx  uisdocker1.uisad.uis.edu:8443;
	sudo docker pull  uisdocker1.uisad.uis.edu:8443/ubuntu-php-fpm-apache:latest;
fi 

# See if it is running/started...
#
grep --quiet  'Exited ' /tmp/$$_docker_ps
if [ $? -eq 0 ] ; then
	sudo docker start $containerID
	if [ $? -ne 0 ] ; then
	   continue   # failed to start (eg port conflict)
        fi
fi

