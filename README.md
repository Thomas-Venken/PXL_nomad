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
* Runnen van Ansible playbooks op alle machines
* Opstarten van de interface voor Nomad.
* Opstarten van de interface voor Consul.

Per VM worden de volgende roles geinstalleerd:
* Docker
* Nomad
* Consul

```ansible
---
- name: playbook for server vm
  hosts: servers
  become: yes

  roles:
    - role: software/nomad
    - role: software/consul
    - role: software/docker
  
```
```ansible
---
- name: playbook for client vm
  hosts: clients
  become: yes

  roles:
    - role: software/nomad
    - role: software/consul
    - role: software/docker

```

Beide de roles Nomad, Consul en Docker voeren de volgende handlers.yml en task.yml

Nomad:
```bash

```

Consul
```bash
```

Docker
´´´bash
´´´

## Verdeling van taken
Thomas heeft in essentie de barebones van het script geschreven. Daarna hebben we voor de rest
samen dit script aangepast en uiteindelijk opgesplitst in meerdere kleinere scripts. Ook hebben we het grootste
deel van het 'bugfixen' samen gedaan. De README.md is geschreven door Jens.
