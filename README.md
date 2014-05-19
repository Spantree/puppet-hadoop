puppet-hadoop
=============

Vagrant+yaml+hadoop+puppet

Deploying on AWS

```apt-get install git librarian-puppet``` 
```export FACTER_hostname=dev1```
```puppet apply puppet/manifests/base.pp --trace --debug --modulepath=puppet/modules/ --hiera_config=hiera.yaml```

Starting Hadoop
===============

```$HADOOP_HOME/bin/hadoop namenode -format```
```$HADOOP_HOME/bin/start-all.sh```
```$HADOOP_HOME/bin/hadoop fs -mkdir /hbase```

Starting Hbase
===============

```$HBASE_HOME/bin/start-hbase.sh```
