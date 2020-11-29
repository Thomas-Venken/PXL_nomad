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

  config.vbguest.auto_update = false

  config.vm.provider :virtualbox do |virtualbox, override|
    virtualbox.customize ["modifyvm", :id, "--memory", 2048]
  end

  config.vm.provider :lxc do |lxc, override|
    override.vm.box = "visibilityspots/centos-7.x-minimal"
  end

  config.vm.define "server" do |server|
    server.vm.box = "centos/7"
    server.vm.hostname = "server"
	  server.vm.network "private_network", ip: "192.168.2.15"
	  server.vm.network "forwarded_port", guest: 4646, host: 4646, auto_correct: true, host_ip: "127.0.0.1"
    server.vm.network "forwarded_port", guest: 8500, host: 8500, auto_correct: true, host_ip: "127.0.0.1"

    server.vm.provision "ansible_local" do |ansible|
      ansible.config_file = "ansible/ansible.cfg"
      ansible.playbook = "ansible/plays/server.yml"
      ansible.groups = {
        "servers" => ["server"],
      }
	  ansible.host_vars = {}
    end
  end

  config.vm.define "client1" do |client1|
    client1.vm.box = "centos/7"
    client1.vm.hostname = "client1"
	  client1.vm.network "private_network", ip: "192.168.2.16"
    
    client1.vm.provision "ansible_local" do |ansible|
      ansible.config_file = "ansible/ansible.cfg"
      ansible.playbook = "ansible/plays/client.yml"
      ansible.groups = {
        "clients" => ["client1"],
      }
	  ansible.host_vars = {}
    end
  end

  config.vm.define "client2" do |client2|
    client2.vm.box = "centos/7"
    client2.vm.hostname = "client2"
    client2.vm.network "private_network", ip: "192.168.2.17"
    
    client2.vm.provision "ansible_local" do |ansible|
      ansible.config_file = "ansible/ansible.cfg"
      ansible.playbook = "ansible/plays/client.yml"
      ansible.groups = {
        "clients" => ["client2"],
      }
	  ansible.host_vars = {}
    end
  end  
end
```
De Vagrantfile behandelt de volgende delen:
* Statische IP's toevoegen aan elke machine.
* Runnen van individuele en algemene scripts (Zie volgende deel).
* Opstarten van de nomad server en clients.
* Opstarten van de consul server en clients.
* Opstarten van de interface voor Nomad.
* Opstarten van de interface voor Consul.

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
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum -y install docker-ce
sudo yum -y install nomad
sudo yum -y install consul
sudo systemctl enable docker
sudo systemctl start docker
sudo sed -i '$ a export NOMAD_ADDR=http://192.168.2.15:4646' .bashrc
```
Wanneer deze dan zijn geinstalleerd, dan wordt vervolgens per VM een individueel script gerunt. Hierin wordt dan de server/client in geconfigureerd.
Op deze server/clients worden beide nomad en consul gezet en gerunt.

Server script:
```bash
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
```
Client script:
```bash
#!/bin/bash
sudo mkdir /opt/nomad/clientX > /dev/null 2>&1
sudo echo "log_level = \"DEBUG\"
data_dir = \"/opt/nomad/clientX\"
name = \"client1-nomad\"
bind_addr = \"192.168.2.X\"
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
sed -i '$ a bind_addr = "192.168.2.X"' /etc/consul.d/consul.hcl
sed -i '$ a node_name = "client1-consul"' /etc/consul.d/consul.hcl
sudo systemctl start consul.service
```
De 'X' in het bovenstaande script staat voor het nummer/IP-address van de client.

Uiteindelijk starten we manueel een job op via het volgende commando:
```bash
    $ nomad job run -address=http://192.168.2.15:4646 /opt/nomad/webserver.nomad
```

In het volgende gedeelte staan de screenshots van de werking.

## Webinterface en resultaat
![Nomad Server](/screenshots/Nomad-Server.png)
![Nomad Clients](/screenshots/Nomad-Clients.png)
![Consul](/screenshots/Consul.png)
![Consul Server](/screenshots/Consul-Server.png)
![Consul Clients](/screenshots/Consul-Clients.png)
![Consul Server & Clients](/screenshots/Consul-Nomad-Server-en-Clients.png)
![Nomad Job](/screenshots/Nomad-Job.png)
![Nomad Job Allocation](/screenshots/Nomad-Job-Allocation.png)

## Verdeling van taken
Thomas heeft in essentie de barebones van het script geschreven. Daarna hebben we voor de rest
samen dit script aangepast en uiteindelijk opgesplitst in meerdere kleinere scripts. Ook hebben we het grootste
deel van het 'bugfixen' samen gedaan. De README.md is geschreven door Jens.
