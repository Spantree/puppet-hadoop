class hadoop {
  include java7
  Exec { path => ['/usr', '/usr/bin', '/usr/local/bin', '/usr/local/sbin', '/usr/sbin', '/sbin', '/bin','/usr/local/hadoop-1.2.1/bin/','/usr/local/hadoop-1.2.1/sbin/'] }
  if $slaves_data[$hostname]["type"] =~ /^(NameNode|DataNode)/ {
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
    augeas { "mapred-site.xml":
      incl    => "/usr/local/hadoop-1.2.1/conf/mapred-site.xml",
      lens    => "Xml.lns",
      changes => [
        "set configuration/property[1]/name/#text 'mapred.job.tracker'",
        "set configuration/property[1]/value/#text '${hostname}:9001'",
      ],
      require => Wget::Download["hadoop"]
    }
    augeas { "core-site.xml":
      incl    => "/usr/local/hadoop-1.2.1/conf/core-site.xml",
      lens    => "Xml.lns",
      changes => [
        "set configuration/property[1]/name/#text 'hadoop.tmp.dir'",
        "set configuration/property[1]/value/#text '/tmp'",
        "set configuration/property[1]/description/#text 'tmp folder for data'",
        "set configuration/property[2]/name/#text 'fs.default.name'",
        "set configuration/property[2]/value/#text 'hdfs://${hostname}:9000'",
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
    exec{ '/usr/local/hadoop-1.2.1/conf/hadoop-env.sh':
      command => "cat /etc/profile.d/set_java_home.sh | grep -v PATH >> /usr/local/hadoop-1.2.1/conf/hadoop-env.sh",
      unless => "grep -ic usr/lib/jvm/java-7-oracle/ /usr/local/hadoop-1.2.1/conf/hadoop-env.sh",
      require => [Augeas['core-site.xml'],Augeas['hdfs-site.xml']]
    }
    ######

    }
    if $slaves_data[$hostname]["type"] =~ /NameNode/ {
      $slaves = hiera('slaves',false)
      file {'slaves':
        content => $slaves,
        path => "/usr/local/hadoop-1.2.1/conf/slaves",
        require => Wget::Download["hadoop"]
      }
    }
}
