#!/bin/bash

sudo mkdir /opt/nomad/server > /dev/null 2>&1
sed -i '2s/^/log_level = "DEBUG"/' /etc/nomad.d/nomad.hcl
sed -i 's/0.0.0.0/192.168.2.15/g' /etc/nomad.d/nomad.hcl
sed -i 's/\/data/\/server/g' /etc/nomad.d/nomad.hcl
sed -i 's/127.0.0.1/192.168.2.15/g' /etc/nomad.d/nomad.hcl
sudo systemctl start nomad.service
sed -i 's/#server = true/server = true/g' /etc/consul.d/consul.hcl
sed -i 's/#bootstrap_expect=3/bootstrap_expect=1/g' /etc/consul.d/consul.hcl
sed -i '$ a bind_addr = "192.168.2.15"' /etc/consul.d/consul.hcl
sudo systemctl start consul.service
