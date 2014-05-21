# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
PROJECT_NAME = "chicago-news-crawler"
require 'yaml'
yml = YAML.load_file("puppet/hieradata/common.yaml")
secyml = YAML.load_file("puppet/hieradata/secrets.yaml")

slaves=yml['slaves_data']
p slaves
nodes=yml['nodes']

awsdata=yml['awsdata']
#creds
awscreds=secyml['awscreds']
aws_key = awscreds['key']
aws_secret = awscreds['secret']
aws_pair = awscreds['pair']
#projectname=yml['projectname']
#net settings
aws_secgroup = awsdata['secgroup']
aws_subnet = awsdata['subnet']

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  slaves.select {|key,value| value['state'] == 1}.each do |key, value|

    #inital stuff
    ami = value['ami']
    shape = value['shape']
    hostname = key
    ipaddress = value['addr']
    cpu = value['cpu']
    mem = value['mem']
    #

    config.vm.define key  do |key|
      key.vm.box = "ubuntu/trusty64"
      key.vm.network :private_network, ip: ipaddress
      key.vm.hostname = hostname
      key.vm.provider :virtualbox do |v, override|
        v.customize ["modifyvm", :id, "--memory", mem]
        v.customize ["modifyvm", :id, "--cpus", cpu]
        override.vm.network :private_network, ip: "192.168.244.100"
      end
      key.vm.provider :aws do |aws, override|
        aws.access_key_id = aws_key
        aws.secret_access_key = aws_secret
        aws.keypair_name = aws_pair
        aws.ami = ami
        aws.instance_type = shape
        aws.tags["Name"] = hostname
        aws.security_groups = [aws_secgroup]
        aws.subnet_id = aws_subnet
        aws.private_ip_address = ipaddress
        aws.elastic_ip= true
        override.ssh.username = "ubuntu"
        override.ssh.private_key_path ="~/Downloads/elasticsearch.pem"
        override.vm.box = "dummy"
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
          "hostname" => hostname 
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
