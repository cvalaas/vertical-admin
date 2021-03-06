$vsql_major_version = '8.1'
$vsql_version = "${vsql_major_version}.1-13"

package { 'vsql':
  ensure          => present,
  provider        => 'rpm',
  name            => 'vertica-client-fips',
  source          => "https://my.vertica.com/client_drivers/${vsql_major_version}.x/${vsql_version}/vertica-client-fips-${vsql_version}.${::architecture}.rpm",
  install_options => [
    '--noscripts',
  ],
}
-> exec { 'Add vertica to odbc':
  command => '/usr/bin/odbcinst -d -i -f /etc/vertica.ini',
  require => [
    File['/etc/vertica.ini'],
    Package['unixODBC'],
  ],
}

file { '/etc/vertica.ini':
  ensure  => present,
  owner   => root,
  group   => root,
  mode    => '0644',
  content => @(EOF)
[Vertica]
Driver = /opt/vertica/lib64/libverticaodbc.so
Description = HP Vertica ODBC Driver
EOF
}

package { 'unixODBC':
  ensure => present,
}

# Fix missing error XML file
file { '/opt/vertica/lib64/en-US':
  ensure  => 'link',
  target  => '../en-US',
  require => [
    Package['vsql'],
  ],
}

# Put VSQL on the path
file { '/usr/local/bin/vsql':
  ensure  => 'link',
  target  => '/opt/vertica/bin/vsql',
  require => [
    Package['vsql'],
  ],
}

file { "/etc/profile.d/${project_name}.sh":
  ensure  => present,
  owner   => root,
  group   => root,
  mode    => '0755',
  content => @(EOF)
export VSQL_HOST="$(nubis-metadata NUBIS_ENVIRONMENT).vertical.service.consul"
export VSQL_USER=dbadmin
EOF
}
