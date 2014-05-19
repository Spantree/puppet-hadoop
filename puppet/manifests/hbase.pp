class hbase {
  include java7
  Exec { path => ['/usr', '/usr/bin', '/usr/local/bin', '/usr/local/sbin', '/usr/sbin', '/sbin', '/bin','/usr/local/hadoop-1.2.1/bin/','/usr/local/hadoop-1.2.1/sbin/'] }
  $testdir = "/usr/local/"
  $hbasever = "hbase-0.90.4"
  $hbaselink = "http://archive.apache.org/dist/hbase/hbase-0.90.4/${hbasever}.tar.gz"
  $hbaselibslink = "http://s3.amazonaws.com/hbase-jars/hbase-090.tar.gz"
  $hbaselibs = "hbase-090"
  $hbaselibsdest = "${testdir}/hbase-0.90.4/lib/"

  file {
    "$hbaselibsdest/hadoop-core-0.20-append-r1056497.jar":
      ensure => "absent",
      require => Wget::Download["hbase-libs"];
    "$hbaselibsdest/$hbaselibs.tar.gz":
      ensure => "absent",
      require => File["$hbaselibsdest/hadoop-core-0.20-append-r1056497.jar"];

  }
  wget::download {
    "hbase-libs":
      url => $hbaselibslink,
      app => $hbaselibs,
      destination => $hbaselibsdest,
      require => Wget::Download["hbase"]
  }
  wget::download {
    "hbase":
      url => $hbaselink,
      app => $hbasever,
      destination => $testdir;
  }
  augeas { "hbase-site.xml":
    incl    => "${testdir}/${hbasever}/conf/hbase-site.xml",
    lens    => "Xml.lns",
    changes => [
      "set configuration/property[1]/name/#text 'hbase.rootdir'",
      "set configuration/property[1]/value/#text 'hdfs://${hostname}:9000/hbase'",
      "set configuration/property[2]/name/#text 'hbase.cluster.distributed'",
      "set configuration/property[2]/value/#text 'true'",
    ],
    require => Wget::Download["hbase"]
  }
  exec{ 'hbase-env.sh':
    command => "cat /etc/profile.d/set_java_home.sh | grep -v PATH >> ${testdir}/${hbasever}/conf/hbase-env.sh",
    unless => "grep -ic usr/lib/jvm/java-7-oracle/ ${testdir}/${hbasever}/conf/hbase-env.sh",
    require => [Class['java7'],Wget::Download["hbase"]]
  }
}


