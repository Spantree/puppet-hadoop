class ssh ( $type = "UNSET"){
  augeas { "ssh_config":
    changes => [
      "set /files/etc/ssh/ssh_config/Host/StrictHostKeyChecking 'no'",
    ],
  }
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
  if $type == "priv" {
    file{ 'private_key':
      path => "/root/.ssh/id_rsa",
      mode => "0600",
      content => hiera("id_rsa",false)
    }
  }
}
