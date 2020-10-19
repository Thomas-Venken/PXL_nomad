# Groep 5 - Nomad & consul

Als je het volgende commando geeft, dan starten er drie Virtual Machine's op.

```bash
    $ vagrant up
```

De bovengenoemde VM's zijn:
* server
* client1
* client2

Deze server en clients worden aan de hand van de volgende vagrant file opgestart:
```bash
# -*- mode: ruby -*-
# vi: set ft=ruby :
VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|


  config.vm.define "server" do |subconfig|
    subconfig.vm.box = "centos/7"
    subconfig.vm.hostname = "server"
	  subconfig.vm.network "private_network", ip: "192.168.0.15"
    subconfig.vm.provision "shell", path: "scripts/server.sh"
    subconfig.vm.provision "shell", path: "scripts/webserver.sh"
  end

  config.vm.define "client1" do |subconfig|
    subconfig.vm.box = "centos/7"
    subconfig.vm.hostname = "client1"
	  subconfig.vm.network "private_network", ip: "192.168.0.16"
    subconfig.vm.provision "shell", path: "scripts/client1.sh"
  end

  config.vm.define "client2" do |subconfig|
    subconfig.vm.box = "centos/7"
    subconfig.vm.hostname = "client2"
	  subconfig.vm.network "private_network", ip: "192.168.0.17"
    subconfig.vm.provision "shell", path: "scripts/client2.sh"
  end

  config.vm.provider :virtualbox do |virtualbox, override|
    virtualbox.customize ["modifyvm", :id, "--memory", 2048]
  end

  config.vm.provider :lxc do |lxc, override|
    override.vm.box = "visibilityspots/centos-7.x-minimal"
  end

  config.vm.provision "shell", path: "scripts/install.sh"
end
```
Per VM wordt er het install.sh script gerunt. Deze installeert:
* Docker
* Nomad
* Consul

Wanneer deze dan zijn geinstalleerd, dan wordt vervolgens per VM een individueel script gerunt. Hierin wordt dan de server/client in geconfigureerd.

Server script:
```bash
#!/bin/bash

sudo mkdir /opt/nomad/server > /dev/null 2>&1
sudo echo "# Increase log verbosity
log_level = \"DEBUG\"
# Set server ip
bind_addr = \"192.168.0.15\"

# Setup data dir
data_dir = \"/opt/nomad/server\"

# Enable the server
server {
    enabled = true

    # Self-elect, should be 3 or 5 for production
    bootstrap_expect = 1
}" >  /etc/nomad.d/server.hcl
```
Client script:
```bash
#!/bin/bash

sudo mkdir /opt/nomad/clientX > /dev/null 2>&1
sudo echo "# Increase log verbosity
log_level = \"DEBUG\"

# Setup data dir
data_dir = \"/opt/nomad/clientX\"

# Give the agent a unique name. Defaults to hostname
name = \"clientX\"

# Enable the client
client {
    enabled = true

    # For demo assume we are talking to server1. For production,
    # this should be like "nomad.service.consul:4647" and a system
    # like Consul used for service discovery.
    servers = [\"192.168.0.15:4647\"]
	network_interface=\"eth1\"
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
}" > /etc/nomad.d/clientX.hcl
```
De 'X' in het bovenstaande script staat voor het nummer van de client.
