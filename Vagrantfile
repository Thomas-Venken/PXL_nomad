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
