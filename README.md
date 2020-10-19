# Groep 5 - Nomad & consul

## Installatie en Configuratie
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
	  subconfig.vm.network "private_network", ip: "192.168.2.15"
    subconfig.vm.provision "shell", path: "scripts/server.sh"
	  subconfig.vm.network "forwarded_port", guest: 4646, host: 4646, auto_correct: true, host_ip: "127.0.0.1"
	  subconfig.vm.provision "shell", inline: "screen -S nomad  -dm sudo nomad  agent -config /etc/nomad.d/server.hcl"
    subconfig.vm.provision "shell", path: "scripts/webserver.sh"
  end

  config.vm.define "client1" do |subconfig|
    subconfig.vm.box = "centos/7"
    subconfig.vm.hostname = "client1"
	  subconfig.vm.network "private_network", ip: "192.168.2.16"
    subconfig.vm.provision "shell", path: "scripts/client1.sh"
	  subconfig.vm.provision "shell", inline: "screen -S nomad  -dm sudo nomad  agent -config /etc/nomad.d/client1.hcl"
  end

  config.vm.define "client2" do |subconfig|
    subconfig.vm.box = "centos/7"
    subconfig.vm.hostname = "client2"
	  subconfig.vm.network "private_network", ip: "192.168.2.17"
    subconfig.vm.provision "shell", path: "scripts/client2.sh"
	  subconfig.vm.provision "shell", inline: "screen -S nomad  -dm sudo nomad  agent -config /etc/nomad.d/client2.hcl"
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
De Vagrantfile behandelt de volgende delen:
* Statische IP's toevoegen aan elke machine.
* Runnen van individuele en algemene scripts (Zie volgende deel).
* Opstarten van de nomad servers en clients.
* Opstarten van de interface voor Nomad.

Per VM wordt er het install.sh script gerunt. Deze installeert:
* Eventuele Linux updates
* Docker
* Nomad
* Consul

```bash
#!/bin/bash

availableUpdates=$(sudo yum -q check-update | wc -l)

if [ $availableUpdates -gt 0 ]; then
    sudo yum upgrade -y;
else
    echo $availableUpdates "updates available"
fi

sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install docker
sudo yum -y install nomad
sudo yum -y install consul
sudo systemctl enable docker
```
Wanneer deze dan zijn geinstalleerd, dan wordt vervolgens per VM een individueel script gerunt. Hierin wordt dan de server/client in geconfigureerd.

Server script:
```bash
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
    servers = [\"192.168.2.15:4647\"]
	network_interface=\"eth1\"
}

# Modify our port to avoid a collision with server1
ports {
    http = 565X
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

## Verdeling van taken
Thomas heeft in essentie de barebones van het script geschreven. Daarna hebben we voor de rest
samen dit script aangepast en uiteindelijk opgesplitst in meerdere kleinere scripts. Ook hebben we het grootste
deel van het 'bugfixen' samen gedaan. De README.md is geschreven door Jens.
