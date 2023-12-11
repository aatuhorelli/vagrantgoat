# -*- mode: ruby -*-
# vi: set ft=ruby :

$minion = <<MINION
sudo apt-get update
sudo apt-get -qy install salt-minion salt-master
echo "master: 192.168.58.1">/etc/salt/minion
sudo service salt-minion restart
MINION


Vagrant.configure("2") do |config|
	config.vm.box = "debian/bullseye64"

	config.vm.define "webgoat" do |testi|
		testi.vm.provision :shell, inline: $minion
		testi.vm.network "private_network", ip: "192.168.58.100"
		testi.vm.hostname = "webgoat"
	end
	
	config.vm.provider "virtualbox" do |vm|
		vm.memory = 4096
		vm.cpus = 2
	end
end
