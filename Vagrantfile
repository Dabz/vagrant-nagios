# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "bento/centos-7.1"
  config.vm.hostname = "nagios.vagrant.dev"
  config.vm.network :private_network, ip: "192.168.14.28"
  config.vm.provision :shell, path: "scripts/provision-nagios.sh", args: ENV['ARGS']
  config.vm.synced_folder "shared/", "/vagrant", :mount_options => ['dmode=775', 'fmode=775']
  config.vm.synced_folder "scripts/", "/vagrant-scripts", :mount_options => ['dmode=775', 'fmode=775']
  config.vm.provider :virtualbox do |vb|
    vb.gui = false
    vb.customize ["modifyvm", :id, "--memory", "1024"]
  end
end
