define nifi::kerberos_provider (
  $identifier = 'kerberos-provider',
  $provider_class = 'org.apache.nifi.kerberos.KerberosProvider',
  $provider_properties = {},
){

  $default_kerberos_properties = {
    "default_realm" => "NIFI.APACHE.ORG",
    "authentication_expiration" => "12 hours"
  }
  $active_kerberos_provider_properties = deep_merge($default_kerberos_properties, $provider_properties)
  assert_type(Hash[String, String], $active_kerberos_provider_properties)

  $tmp = $active_kerberos_provider_properties.map |$key, $value | {
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

  $normalized_kerberos_provider_properties = hash($flat_tmp)


  concat::fragment { "frag_${identifier}":
    order   => '03',
    target  => "${::nifi::nifi_conf_dir}/login-identity-providers.xml",
    content => template('nifi/idmapping/frag_kerberos_provider.erb')
  }
}