define nifi::local_state_provider (
  $identifier = 'local-provider',
  $provider_class = 'org.apache.nifi.controller.state.providers.local.WriteAheadLocalStateProvider',
  $provider_properties = {},
){

  assert_type(Hash, $provider_properties)

  $default_provider_properties = {
    'directory' => './state/local',
    'always_sync' => 'false',
    'partitions' => '16',
    'checkpoint_interval' => '2 mins'
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
      #notify {"${key}: ${$cap_key_spec}":}
      $cap_key_spec
    }

    $cap_key = join($cap_keyspecs, ' ')
    [$cap_key, $value]
  }

  $flat_tmp = flatten($tmp)

  $normalized_local_provider_properties = hash($flat_tmp)

  concat::fragment { "frag_local_state_provider":
    order   => '02',
    target  => "${::nifi::nifi_conf_dir}/state-management.xml",
    content => template('nifi/statemgmt/frag_local_provider.erb')
  }
}