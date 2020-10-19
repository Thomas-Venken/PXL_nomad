#!/bin/bash

sudo mkdir /opt/nomad/client2 > /dev/null 2>&1
sudo echo "# Increase log verbosity
log_level = \"DEBUG\"

# Setup data dir
data_dir = \"/opt/nomad/client2\"

# Give the agent a unique name. Defaults to hostname
name = \"client2-nomad\"

# Enable the client
client {
    enabled = true

    # For demo assume we are talking to server1. For production,
    # this should be like \"nomad.service.consul:4647\" and a system
    # like Consul used for service discovery.
    servers = [\"192.168.2.15:4647\"]
}

# Modify our port to avoid a collision with server1
ports {
    http = 5657
}

# Disable the dangling container cleanup to avoid interaction with other clients
plugin \"docker\" {
  config {
    gc {
      dangling_containers {
        enabled = false
      }
    }
  }
}" > /etc/nomad.d/client2.hcl
sudo rm -f /etc/nomad.d/nomad.hcl

sudo systemctl start nomad.service

sudo echo "data_dir = \"/opt/consul\"

client_addr= \"0.0.0.0\"

ui = true

#retry_join = [\"consul.domain.internal\"]
retry_join = [\"192.168.2.15\"]
#retry_join = [\"[::1]:8301\"]
#retry_join = [\"consul.domain.internal\", \"10.0.4.67\"]

bind_addr = \"192.168.2.17\"
node_name = \"client2-consul\"


" >> /etc/consul.d/consul.hcl
sudo systemctl start consul.service