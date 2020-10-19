#!/bin/bash

sudo mkdir /opt/nomad/server > /dev/null 2>&1
sudo echo "# Increase log verbosity
log_level = \"DEBUG\"
# Set server ip
bind_addr = \"192.168.2.15\"

# Setup data dir
data_dir = \"/opt/nomad/server\"

# Enable the server
server {
    enabled = true

    # Self-elect, should be 3 or 5 for production
    bootstrap_expect = 1
}" >  /etc/nomad.d/server.hcl
sudo rm -f /etc/nomad.d/nomad.hcl
sudo systemctl start nomad.service
sudo echo "data_dir = \"/opt/consul\"
client_addr= \"0.0.0.0\"
ui = true
server = true
bootstrap_expect=1
#retry_join = [\"consul.domain.internal\"]
#retry_join = [\"10.0.4.67\"]
#retry_join = [\"[::1]:8301\"]
#retry_join = [\"consul.domain.internal\", \"10.0.4.67\"]
bind_addr = \"192.168.2.15\"
" >> /etc/consul.d/consul.hcl
sudo systemctl start consul.service
