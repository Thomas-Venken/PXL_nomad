#!/bin/bash

sudo mkdir /opt/nomad/server > /dev/null 2>&1
sudo echo "# Increase log verbosity
log_level = \"DEBUG\"

# Setup data dir
data_dir = \"/opt/nomad/server\"

# Enable the server
server {
    enabled = true

    # Self-elect, should be 3 or 5 for production
    bootstrap_expect = 1
}" >  /etc/nomad.d/server.hcl
sudo nomad agent -config /etc/nomad.d/server.hcl &
sudo mkdir /opt/nomad/client1 > /dev/null 2>&1
sudo echo "# Increase log verbosity
log_level = "DEBUG"

# Setup data dir
data_dir = \"/opt/nomad/client1\"

# Give the agent a unique name. Defaults to hostname
name = \"client1\"

# Enable the client
client {
    enabled = true

    # For demo assume we are talking to server1. For production,
    # this should be like "nomad.service.consul:4647" and a system
    # like Consul used for service discovery.
    servers = [\"127.0.0.1:4647\"]
}

# Modify our port to avoid a collision with server1
ports {
    http = 5656
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
  }
}" > /etc/nomad.d/client1.hcl
sudo mkdir /opt/nomad/client2 > /dev/null 2>&1
sudo echo "# Increase log verbosity
log_level = \"DEBUG\"

# Setup data dir
data_dir = \"/opt/nomad/client2\"

# Give the agent a unique name. Defaults to hostname
name = \"client2\"

# Enable the client
client {
    enabled = true

    # For demo assume we are talking to server1. For production,
    # this should be like "nomad.service.consul:4647" and a system
    # like Consul used for service discovery.
    servers = [\"127.0.0.1:4647\"]
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
sudo nomad agent -config /etc/nomad.d/client1.hcl &
sudo nomad agent -config /etc/nomad.d/client2.hcl &

