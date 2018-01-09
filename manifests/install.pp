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
  }
  file {$::nifi::nifi_work_dir:
    ensure => 'directory',
    owner => 'nifi',
    group => 'nifi',
    mode => '0755',
    require => [Package[$::nifi::package_name], User['nifi']]
  }
  file {$::nifi::nifi_flow_dir:
    ensure => 'directory',
    owner => 'nifi',
    group => 'nifi',
    mode => '0755',
    require => [Package[$::nifi::package_name], User['nifi']]
  } ->
  file {'/var/run/nifi':
    ensure => 'directory',
    owner => 'nifi',
    group => 'nifi',
    mode => '0755'
  }
  file {'/var/lib/nifi':
    ensure => 'directory',
    owner => 'nifi',
    group => 'nifi',
    mode => '0755',
    require => [Package[$::nifi::package_name], User['nifi']]
  }

  file {'/usr/lib/tmpfiles.d/nifi.conf':
   ensure => 'present',
   content => 'd /run/nifi 0755 nifi nifi -',
   mode => '0644',
   require => User['nifi']
  }
}
