define nifi::cluster_state_provider (
  $identifier = 'zk-provider',
  $provider_class = 'org.apache.nifi.controller.state.providers.zookeeper.ZooKeeperStateProvider',
  $provider_properties = {},
){

  assert_type(Hash[String,String], $provider_properties)

  $default_provider_properties = {
    'connect_string' => '',
    'root_node' => '/nifi',
    'session_timeout' => '10 seconds',
    'access_control' => 'Open'
  }

  $active_provider_properties = deep_merge($default_provider_properties,$provider_properties)
  assert_type(Hash[String, String], $active_provider_properties)

  $tmp = $active_provider_properties.map |$key, $value | {
    #replace single _ with space
    $keyspecs = split($key, '_')
    $cap_keyspecs = $keyspecs.map | $key_spec| {
      #if part is all uppercase, do not transform
      if $key_spec =~ /[A-Z0-9]+/ {
        $cap_key_spec = $key_spec
      }else {
        $cap_key_spec = capitalize($key_spec)
      }
      $cap_key_spec
    }

    $cap_key = join($cap_keyspecs, ' ')
    [$cap_key, $value]
  }

  $flat_tmp = flatten($tmp)

  $normalized_cluster_provider_properties = hash($flat_tmp)

  concat::fragment { "frag_cluster_state_provider":
    order   => '03',
    target  => '/opt/nifi/conf/state-management.xml',
    content => template('nifi/statemgmt/frag_cluster_provider.erb')
  }
}