import 'hbase.pp'
import 'hadoop.pp'
import 'ssh.pp'
include java7
###load the main hash
$slaves_data = hiera("slaves_data",false)
Exec { path => ['/usr', '/usr/bin', '/usr/local/bin', '/usr/local/sbin', '/usr/sbin', '/sbin', '/bin','/usr/local/hadoop-1.2.1/bin/','/usr/local/hadoop-1.2.1/sbin/'] }

file {"/tmp/puppetwasher":
  ensure => "created",
}
case $slaves_data[$hostname]["type"] {
  "NameNode": { 
  class {'hadoop':} 
  class { 'ssh' : type => 'priv'} 
  }
  "Datanode": { 
  class {'hadoop':} 
  class { 'ssh' : type => 'pub'} 
  }
  "HbaseNode": { 
  class {'hbase':} 
  class { 'ssh' : type => 'pub'} 
  "DataNode,HbaseNode": {
  class {'hbase':} 
  class {'hadoop':} 
  class { 'ssh' : type => 'priv'} 
  }
}
