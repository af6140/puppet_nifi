define nifi::file_authorizer (
  $identifier = 'file-provider',
  $provider_class = 'org.apache.nifi.authorization.FileAuthorizer',
  $provider_properties = {},
){

  $default_properties = {
    "authorizations_file" => "./conf/authorizations.xml",
    "users_file" => "./conf/users.xml",
    "initial_admin_identity" => "",
    "legacy_authorized_users_file" => ""
  }
  $active_provider_properties = deep_merge($default_properties, $provider_properties,)
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

  $normalized_file_authorizer_properties = hash($flat_tmp)

  concat::fragment { "frag_authorizer_${identifier}":
    order   => '02',
    target  => "${::nifi::nifi_conf_dir}/authorizers.xml",
    content => template('nifi/authorizer/frag_file_authorizer.erb')
  }
}