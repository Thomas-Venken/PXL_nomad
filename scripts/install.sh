#!/bin/bash

availableUpdates=$(sudo yum -q check-update | wc -l)

if [ $availableUpdates -gt 0 ]; then
    sudo yum upgrade -y;
else
    echo $availableUpdates "updates available"
fi

sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum -y install docker-ce
sudo yum -y install nomad
sudo yum -y install consul
sudo systemctl enable docker
sudo systemctl start docker
sudo sed -i '$ a export NOMAD_ADDR=http://192.168.2.15:4646' .bashrc
