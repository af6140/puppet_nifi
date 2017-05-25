# == Class nifi::install
#
# This class is called from nifi for install.
#
class nifi::install {
  group {'nifi':
    ensure=> 'present',
  } ->
  user {'nifi':
      ensure => 'present',
      home => '/var/lib/nifi',
      groups => ['nifi']
  }

  package { $::nifi::package_name:
    ensure => $::nifi::package_version
  } ->
  file {'/opt/nifi/flow':
    ensure => 'directory',
    owner => 'nifi',
    group => 'nifi',
    mode => '0755',
  } ->
  file {'/var/run/nifi':
    ensure => 'directory',
    owner => 'nifi',
    group => 'nifi',
    mode => '0755'
  }
}
