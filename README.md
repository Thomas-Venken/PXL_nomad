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
    server.vm.network "forwarded_port", guest: 9090, host: 9090, auto_correct: true, host_ip: "127.0.0.1"

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
* Node_exporter (Clients)
* Nomad_jobs (Server)

Voor de server zijn deze geinstalleerd
```ansible
---
- name: playbook for server vm
  hosts: servers
  become: yes

  roles:
    - role: software/nomad
    - role: software/consul
    - role: software/docker
    - role: software/node_exporter
    - role: software/nomad_jobs
```

Voor de clients zijn deze geinstalleerd
```ansible
---
- name: playbook for client vm
  hosts: clients
  become: yes

  roles:
    - role: software/nomad
    - role: software/consul
    - role: software/docker
    - role: software/node_exporter

```

De Nomad, Consul en Docker roles zijn in de vorige opdrachten al aangehaald. De volgende
zijn de nieuwe roles namelijk:

Node_exporter (Tasks)
```ansible
---
- name: Download node_exporter
  get_url:
    url: https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz
    dest: /home/vagrant
    mode: '0776'
    
- name: Extract node_exporter
  unarchive:
    src: /home/vagrant/node_exporter-1.0.1.linux-amd64.tar.gz
    dest: /home/vagrant

- name: Move node_exporter
  command: mv /home/vagrant/node_exporter-1.0.1.linux-amd64/node_exporter /usr/local/bin/

- name: Node_exporter .service file
  template: 
    src: node_exporter.service.sh.j2
    dest: /etc/systemd/system/node_exporter.service

- name: Start node_exporter
  service:
    name: node_exporter
    state: started
```

Node_exporter (Handlers)
```
---
- name: Started Node_exporter
  service:
    name: node_exporter
    state: started
```

Node_exporter (Template)
```ansible
[Unit]
Description=Node Exporter
After=network.target
 
[Service]
User=vagrant
Group=vagrant
Type=simple
ExecStart=/usr/local/bin/node_exporter
 
[Install]
WantedBy=multi-user.target
```

Nomad_jobs (Tasks)
```
---
- name: Create a directory for Prometheus.yml
  file:
    path: /opt/prometheus
    state: directory
    mode: '0755'

- name: Prometheus.yml template
  template: 
    src: prometheus.yml.sh.j2
    dest: /opt/prometheus/prometheus.yml

- name: Prometheus template
  template: 
    src: prometheus.hcl.sh.j2
    dest: /opt/nomad/prometheus.hcl
  vars:
    job_name: prometheus
    job_image: prom/prometheus:latest
    job_port: 9090
  notify: Start prometheus

- name: Grafana template
  template: 
    src: jobs.hcl.sh.j2
    dest: /opt/nomad/grafana.hcl
  vars:
    job_name: grafana
    job_image: grafana/grafana:latest
    job_port: 3000
  notify: Start grafana

- name: Alertmanager template
  template: 
    src: jobs.hcl.sh.j2
    dest: /opt/nomad/alertmanager.hcl
  vars:
    job_name: alertmanager
    job_image: prom/alertmanager:latest
    job_port: 9093
  notify: Start alertmanager

- name: webserver template
  template: 
    src: webserver.hcl.j2
    dest: /opt/nomad/webserver.hcl
  notify: Start webserver
```
## Verdeling van taken
