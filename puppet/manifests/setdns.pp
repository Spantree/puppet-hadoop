class setDns {
  $slaves_data.each |$node,$val| {
    if $val['type'] =~ /DnsNode/ {
      file {"/run/resolvconf/resolv.conf":
        content => "nameserver ${val['addr']}",
      }
    }
  }
}
