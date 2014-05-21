import 'hbase.pp'
import 'hadoop.pp'
import 'ssh.pp'
import 'setdns.pp'
include java7
###load the main hash
$slaves_data = hiera("slaves_data",false)

Exec { path => ['/usr', '/usr/bin', '/usr/local/bin', '/usr/local/sbin', '/usr/sbin', '/sbin', '/bin','/usr/local/hadoop-1.2.1/bin/','/usr/local/hadoop-1.2.1/sbin/'] }
#we set dns with any DnsNode in commons.yaml
class {'setDns':}
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
  }
  "NameNode,HbaseNode": {
    class {'hbase':} 
    class {'hadoop':} 
    class { 'ssh' : type => 'priv'} 
  }
  /DnsNode/: {
    class { 'dnsmasq': }
    $slaves_data.each |$node,$val| { 
    notify{"Adding ${node} -> ${val['addr']}":} 
    dnsmasq::address { "${node}":ip  => $val['addr']
    }
    }
  }
}
