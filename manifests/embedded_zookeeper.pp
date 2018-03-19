define nifi::embedded_zookeeper (
  Array[String] $members = [],
  Array[Integer[1,255]] $ids= [],
  $client_port           = 2181
) {

  file { "${::nifi::nifi_home}/state":
          ensure => 'directory',
          owner  => 'nifi',
          group  => 'nifi',
          mode   => '0755'
  } ->
  file { "${::nifi::nifi_home}/state/zookeeper":
    ensure => 'directory',
    owner  => 'nifi',
    group  => 'nifi',
    mode   => '0755'
  }

  notify {"cluster members: ${members}": }
  if !empty($members) {
    $members_array = $members.map |$index, $member| {
      $real_index = $ids[$index]
      ["server.${real_index}", "${member}:2888:3888"]
    }
    $zookeeper_members_hash = hash(flatten($members_array))

    #write my id
    $members.each |$index, $member| {
      $real_index = $ids[$index]
      #set zookeeper myid
      # echo $id > .state/zookeeper/myid
      if $::fqdn == $member {
          file { "${::nifi::nifi_home}/state/zookeeper/myid":
            ensure  => 'present',
            content => "${real_index}",
            owner   => 'nifi',
            group   => 'nifi',
            mode    => '0644',
            notify => $::nifi::service_notify,
            require => File["${::nifi::nifi_home}/state/zookeeper"],
          }
      }
    }
  }else {
    $zookeeper_members_hash = {
      "zookeeper.1" => "%"
    }
  }
  file { "${nifi::nifi_conf_dir}/zookeeper.properties":
    ensure  => 'present',
    owner   => 'nifi',
    group   => 'nifi',
    mode    => '644',
    content => template('nifi/zookeeper.properties.erb'),
    notify => $::nifi::service_notify,
    require => File["${::nifi::nifi_home}/state/zookeeper"]
  }
}
