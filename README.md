puppet-hadoop
=============

Vagrant+yaml+hadoop+puppet

Deploying on AWS

apt-get install git librarian-puppet 
export FACTER_hostname=dev1
puppet apply puppet/manifests/base.pp --trace --debug --modulepath=puppet/modules/ --hiera_config=hiera.yaml
