# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
PROJECT_NAME = "chicago-news-crawler"
### attempt #1
require 'yaml'
yml = YAML.load_file("puppet/hieradata/common.yaml")
slaves=yml['slaves_data']
p slaves

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  slaves.select {|key,value| value[3] == 1}.each do |key, value|
    config.vm.define key  do |key|
      key.vm.box = "ubuntu/trusty64"
      key.vm.network :private_network, ip: value[0]
      key.vm.hostname = value[1]
      key.vm.provider :virtualbox do |v, override|
        v.gui = true
        v.customize ["modifyvm", :id, "--memory", 1024]
        v.customize ["modifyvm", :id, "--cpus", 2]
        override.vm.network :private_network, ip: "192.168.244.100"
      end
      key.vm.synced_folder ".", "/usr/local/src/#{PROJECT_NAME}", :create => 'true'
      key.vm.synced_folder "puppet", "/usr/local/etc/puppet", :create => 'true'
      key.vm.provision :shell, :path => 'shell/initial-setup.sh', :args => '/vagrant/shell'
      key.vm.provision :shell, :path => 'shell/update-puppet.sh', :args => '/vagrant/shell'
      key.vm.provision :shell, :path => 'shell/librarian-puppet-vagrant.sh', :args => '/vagrant/shell'

      key.vm.provision :puppet do |key|
        key.manifests_path = 'puppet/manifests'
        key.manifest_file  = "base.pp"
        key.facter = {
          "ssh_username" => "vagrant",
          "host_environment" => "Vagrant",
          "vm_type" => "vagrant",
          "build_apps" => true,
          "hostname" => "mn1.dev.spantree.net"
        }
        key.options = [
          '--trace',
          '--debug',
          '--modulepath=/etc/puppet/modules:/usr/local/etc/puppet/modules',
          "--hiera_config /usr/local/src/#{PROJECT_NAME}/hiera.yaml",
          '--parser future'
        ]
      end
    end
  end
end
