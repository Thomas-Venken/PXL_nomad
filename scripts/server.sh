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
