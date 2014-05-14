node /[d,h,m,n][n,b][0-9]/{
  include java7
  Exec { path => ['/usr', '/usr/bin', '/usr/local/bin', '/usr/local/sbin', '/usr/sbin', '/sbin', '/bin','/usr/local/hadoop-1.2.1/bin/','/usr/local/hadoop-1.2.1/sbin/'] }

  augeas { "ssh_config":
    changes => [
      "set /files/etc/ssh/ssh_config/Host/StrictHostKeyChecking 'no'",
    ],
  }

  ##key or everything should go to hiera
  file {"/tmp/puppetwasher":
    ensure => "created",
  }
  file { "/hdfs":
    ensure => "directory",
    mode   => 777,
    before => Wget::Download["hadoop"]
  }
  file { "/etc/profile.d/hadoop.sh":
    content => "
    export HADOOP_HOME=/opt/hadoop
    export HADOOP_COMMON_LIB_NATIVE_DIR=/opt/hadoop/lib/native
    export HADOOP_OPTS='-Djava.library.path=/opt/hadoop/lib'
    "
  }
  wget::download {
    "hadoop":
      url => "http://mirrors.dcarsat.com.ar/apache/hadoop/common/stable1/hadoop-1.2.1-bin.tar.gz",
      app => "hadoop-1.2.1-bin",
      destination => "/usr/local/",
      require => Class['java7']
  }


  #####ONly node names get this setting
  notify { $hostname: }
  if $hostname =~ /^nn(\d+)\./ {
    file{ 'private_key':
      path => "/root/.ssh/id_rsa",
      mode => "0600",
      content => hiera("id_rsa",false)
    }
    #### i need to fix this so i don't key two arrays
    $slaves = hiera('slaves',false)
    file {'slaves':
      content => $slaves,
      path => "/usr/local/hadoop-1.2.1/conf/slaves",
      require => Wget::Download["hadoop"]
    }
  }
  augeas { "mapred-site.xml":
    incl    => "/usr/local/hadoop-1.2.1/conf/mapred-site.xml",
    lens    => "Xml.lns",
    changes => [
      "set configuration/property[1]/name/#text 'mapred.job.tracker'",
      "set configuration/property[1]/value/#text 'nn1:9001'",
    ],
    require => Wget::Download["hadoop"]
  }
  #exec { 
  #'namenodeformat':
  #  command => "hadoop namenode -format -nonInteractive",
  #  returns => [0,1],
  #  require => Exec['/usr/local/hadoop-1.2.1/conf/hadoop-env.sh'];
  #'startdfs': 
  #  command => "/bin/bash /usr/local/hadoop-1.2.1/bin/start-dfs.sh",
  #  returns => [0,1],
  #  require => Exec['namenodeformat'];
  #'startyarn':
  #  command => "start-yarn.sh",
  #  #returns => [0,1],
  #  require => [Exec['/usr/local/hadoop-2.4.0/etc/hadoop/yarn-env.sh'],Exec['/usr/local/hadoop-2.4.0/etc/hadoop/yarn-env.sh'],Exec['namenodeformat'],Exec['startdfs']];
  #}
  ######
  sshkey{ 'pub_keys':
    ensure   => "present",
    key      => hiera("id_rsa_pub",false),
    target   => "/root/.ssh/id_rsa.pub",
    type     => rsa,
  }
  ssh_authorized_key { 'authorized_keys':
    ensure   => "present",
    key      => hiera("id_rsa_pub",false),
    target   => "/root/.ssh/authorized_keys",
    type     => rsa,
    user     => "root"
  }
  augeas { "core-site.xml":
    incl    => "/usr/local/hadoop-1.2.1/conf/core-site.xml",
    lens    => "Xml.lns",
    changes => [
      "set configuration/property[1]/name/#text 'hadoop.tmp.dir'",
      "set configuration/property[1]/value/#text '/tmp'",
      "set configuration/property[1]/description/#text 'tmp folder for data'",
      "set configuration/property[2]/name/#text 'fs.default.name'",
      "set configuration/property[2]/value/#text 'hdfs://nn1:9000'",
      "set configuration/property[2]/description/#text 'hdfsurl'",
    ],
    require => Wget::Download["hadoop"]
  }
  augeas { "hdfs-site.xml":
    incl    => "/usr/local/hadoop-1.2.1/conf/hdfs-site.xml",
    lens    => "Xml.lns",
    changes => [
      "set configuration/property[1]/name/#text 'dfs.replication'",
      "set configuration/property[1]/value/#text '3'",
    ],
    require => Wget::Download["hadoop"]
  }
  ###this is nastee ,  i hope there was a better way to append things at the end of a file ,  im sure it's a module that everybody would want.
  # exec{ '/usr/local/hadoop-2.4.0/etc/hadoop/yarn-env.sh':
  #  command => "cat /etc/profile.d/hadoop.sh /etc/profile.d/set_java_home.sh | grep -v PATH >> /usr/local/hadoop-2.4.0/etc/hadoop/yarn-env.sh",
  #  unless => "grep -ic hadoop_opts /usr/local/hadoop-2.4.0/etc/hadoop/yarn-env.sh",
  #  require => [Augeas['core-site.xml'],Augeas['hdfs-site.xml']]
  #}
  exec{ '/usr/local/hadoop-1.2.1/conf/hadoop-env.sh':
    command => "cat /etc/profile.d/set_java_home.sh | grep -v PATH >> /usr/local/hadoop-1.2.1/conf/hadoop-env.sh",
    unless => "grep -ic usr/lib/jvm/java-7-oracle/ /usr/local/hadoop-1.2.1/conf/hadoop-env.sh",
    require => [Augeas['core-site.xml'],Augeas['hdfs-site.xml']]
  }
  ######
  $slaves_data = hiera("slaves_data",false)
  file { 'hostfile':
    path => "/etc/hosts",
    content => template("/usr/local/src/chicago-news-crawler/puppet/templates/hosts.erb")
  }

  #### ORDER OF SLAVES AND CONF , START DFS AFTER FILE CHANGES

  #WHAT's LEFT
  #--SSH keys , generation and distribution , datanodes namenodes everything , even itself.
  #--Augueas for hdfs-site ,  core-site
  #--Augeas to etc/hadoop/slaves
  #--Bring up all nodes in order
  #--Name of the master node aka name node has to be bound to the external intrface on etc/hosts
  #--namenode -format
  #-- start-dfs.sh  start-yarn.sh ENV VARS
  #that should be all
  #ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNSW4qbpk7KXL0izm0IvpfSzA+TufVs+MvKrIDYYrHthVCp9TAgWl9feco1dWgHVzK7dPasRbEa9fn2RtF01sV3an+TEUVkCwBolvbn+JpJ/yc1xQfiSNHgFsOZsfVInzUilLguhzGhXtuwzalcIedWQ66PTtvAcf8yUs8SMnZEkDk8TyCk72mvqR8uLSvx93nFuLCxvRPIDT3Lh2EG5I9cHqaXilrIuY+tbXMgFOJ6W34TS/X2jpRnuHmqfLIl6htKs74RyWydhhCx3H7uZjU060dBrzfdRuG7oRIC54LG/5hekPq64CXbvhy5CGIL56fOSQCdt6ICV7WZ7zxCIbn root@mn1



  }
