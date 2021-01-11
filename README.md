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
zijn de nieuwe roles, namelijk:

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
```ansible
---
- name: Started Node_exporter
  service:
    name: node_exporter
    state: started
```

Nomad_jobs (Tasks)
```ansible
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

Nomad_jobs (Handlers)
```ansible
---
- name: Start prometheus
  shell: nomad job run -address=http://{{server_ip}}:4646 /opt/nomad/prometheus.hcl || exit 0

- name: Start grafana
  shell: nomad job run -address=http://{{server_ip}}:4646 /opt/nomad/grafana.hcl || exit 0

- name: Start alertmanager
  shell: nomad job run -address=http://{{server_ip}}:4646 /opt/nomad/alertmanager.hcl || exit 0

- name: Start webserver
  shell: nomad job run -address=http://{{server_ip}}:4646 /opt/nomad/webserver.hcl || exit 0
```

Ook hebben we gebruik gemaakt van templates. De templates van toepassing zijn:

Node_exporter (Service)
```
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

Nomad_jobs (Algemene HCL jobs)
```ansible
job "{{job_name}}" {
	datacenters = ["dc1"] 
	type = "service"

	group "{{job_name}}" {
		count = 1
		network {
			port "{{job_name}}_port" {
			to = {{job_port}}
			static = {{job_port}}
			}
		}
	  task "{{job_name}}" {
		driver = "docker"
		config {
			image = "{{job_image}}"
			ports = ["{{job_name}}_port"]
			logging {
				type = "journald"
				config {
					tag = "{{job_name}}"
				}
			}
		}
		service {
			name = "{{job_name}}"
			tags = ["metrics"]
		}
	  }
	}
}
```

Nomad_jobs (Prometheus Job HCL)
```ansible
job "{{job_name}}" {
	datacenters = ["dc1"] 
	type = "service"

	group "{{job_name}}" {
		count = 1
		network {
			port "{{job_name}}_port" {
			to = {{job_port}}
			static = {{job_port}}
			}
		}
	  task "{{job_name}}" {
		driver = "docker"
		config {
			image = "{{job_image}}"
			ports = ["{{job_name}}_port"]
			logging {
				type = "journald"
				config {
					tag = "{{job_name}}"
				}
			}
        volumes = [
          "/opt/prometheus/:/etc/prometheus/"
        ]
        args = [
          "--config.file=/etc/prometheus/prometheus.yml",
          "--storage.tsdb.path=/prometheus",
          "--web.console.libraries=/usr/share/prometheus/console_libraries",
          "--web.console.templates=/usr/share/prometheus/consoles",
          "--web.enable-admin-api"
        ]
		}
		service {
			name = "{{job_name}}"
		}
	  }
	}
}
```

Nomad_jobs (Prometheus.yml)
```
global:                                       
  scrape_interval:     5s                     
  evaluation_interval: 5s                     
                                              
scrape_configs:                               
                                              
  - job_name: 'nomad_metrics'                 
                                              
    consul_sd_configs:                        
    - server: '192.168.2.15:8500'             
      services: ['nomad-client', 'nomad']     
                                              
    relabel_configs:                          
    - source_labels: ['__meta_consul_tags']   
      regex: '(.*)http(.*)'                   
      action: keep                            
                                              
    scrape_interval: 5s                       
    metrics_path: /v1/metrics                 
    params:                                   
      format: ['prometheus']                  
  - job_name: 'node_exporter'                 
    consul_sd_configs:                        
      - server: '192.168.2.15:8500'           
        services: ['nomad-client']            
    relabel_configs:                          
      - source_labels: [__meta_consul_tags]   
        regex: '(.*)http(.*)'                 
        action: keep                          
      - source_labels: [__meta_consul_service]
        target_label: job                     
      - source_labels: [__address__]          
        action: replace                       
        regex: ([^:]+):.*                     
        replacement: $1:9100                  
        target_label: __address__
  - job_name: 'webserver'

    consul_sd_configs:
    - server: '192.168.2.15:8500'
      services: ['webserver']

    metrics_path: /metrics
```

Nomad_jobs (Webserver voor Prometheus metrics job)
```ansible
job "webserver" {
  datacenters = ["dc1"]

  group "webserver" {
    task "server" {
      driver = "docker"
      config {
        image = "hashicorp/demo-prometheus-instrumentation:latest"
      }

      resources {
        cpu = 500
        memory = 256
        network {
          mbits = 10
          port  "http"{}
        }
      }

      service {
        name = "webserver"
        port = "http"

        tags = [
          "testweb",
          "urlprefix-/webserver strip=/webserver",
        ]

        check {
          type     = "http"
          path     = "/"
          interval = "2s"
          timeout  = "2s"
        }
      }
    }
  }
}
```

## Verdeling van taken
