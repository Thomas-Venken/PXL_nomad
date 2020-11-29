# Groep 5 - Ansible

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

Consul:
```bash
---
- name: Started Consul
  service:
    name: consul
    state: started
```
```bash
---
- name: Add Consul repository
  yum_repository:
    name: consul
    description: add consul repository
    baseurl: https://rpm.releases.hashicorp.com/RHEL/$releasever/$basearch/stable
    gpgkey: https://rpm.releases.hashicorp.com/gpg

- name: Install Consul
  yum:
    name: consul
    state: present

- name: Template Consul file
  template:
    src: consul.sh.j2
    dest: /etc/consul.d/consul.hcl
  notify: Started Consul
```
Nomad:
```bash
---
- name: Started Nomad
  service:
    name: nomad
    state: started
```
```bash
---

- name: Add Nomad repository
  yum_repository:
    name: nomad
    description: add nomad repository
    baseurl: https://rpm.releases.hashicorp.com/RHEL/$releasever/$basearch/stable
    gpgkey: https://rpm.releases.hashicorp.com/gpg

- name: Install Nomad
  yum:
    name: nomad
    state: present

- name: Create a directory if it does not exist
  file:
    path: /opt/nomad/{{inventory_hostname}}
    state: directory
    mode: '0755'

- name: Template Nomad file
  template:
    src: nomad.sh.j2
    dest: /etc/nomad.d/nomad.hcl
  notify: Started Nomad
```
Docker:
´´´bash
---
- name: started docker-ce
  service:
    name: docker.service
    state: started
´´´
```bash
---
- name: add docker-ce repository
  yum_repository:
    name: docker-ce
    description: add docker-ce repository
    baseurl: https://download.docker.com/linux/centos/$releasever/$basearch/stable
    gpgkey: https://download.docker.com/linux/centos/gpg

- name: install docker-ce
  yum:
    name: docker-ce
    state: present
  notify: started docker-ce
```
De Nomad en Consul tasks.yml's importeren de volgende Jinja scripten

Consul:
```bash
# {{ ansible_managed }}

# Full configuration options can be found at https://www.consul.io/docs/agent/options.html

data_dir = "/opt/consul"
client_addr = "0.0.0.0"
ui = true
server = {{consul_server_enable_disable}}
bootstrap_expect={{consul_amount_bootstrap}}
retry_join = ["{{server_ip}}"]
bind_addr = "{{consul_bind_addr}}"
node_name = "{{node_name}}"
```
Nomad:
```bash
# {{ ansible_managed }}

# Full configuration options can be found at https://www.nomadproject.io/docs/configuration

log_level = "DEBUG"
data_dir = "/opt/nomad/{{inventory_hostname}}"
bind_addr = "{{nomad_bind_addr}}"

server {
  enabled = {{nomad_server_enable_disable}}
  bootstrap_expect = 1
}

client {
  enabled = true
  servers = ["{{server_ip}}:{{nomad_server_port}}"]
}
```

## Verdeling van taken
Thomas heeft in essentie de barebones van het script geschreven. Daarna hebben we voor de rest
samen dit script aangepast en uiteindelijk opgesplitst in meerdere kleinere scripts. Ook hebben we het grootste
deel van het 'bugfixen' samen gedaan. De README.md is geschreven door Jens.
