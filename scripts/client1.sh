#!/bin/bash
sudo mkdir /opt/nomad/client1 > /dev/null 2>&1
sudo echo "log_level = \"DEBUG\"
data_dir = \"/opt/nomad/client1\"
name = \"client1-nomad\"
bind_addr = \"192.168.2.16\"
client {
    enabled = true
    servers = [\"192.168.2.15:4647\"]
	network_interface=\"eth1\"
}
ports {
    http = 5656
}
plugin \"docker\" {
  config {
    gc {
      dangling_containers {
        enabled = false
      }
    }
  }
}" > /etc/nomad.d/nomad.hcl
sudo systemctl start nomad.service
sed -i '$ a retry_join = ["192.168.2.15"]' /etc/consul.d/consul.hcl
sed -i '$ a bind_addr = "192.168.2.16"' /etc/consul.d/consul.hcl
sed -i '$ a node_name = "client1-consul"' /etc/consul.d/consul.hcl
sudo systemctl start consul.service
