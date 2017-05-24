define nifi::ldap_provider (
  $identifier = 'ldap-provider',
  $provider_class = 'org.apache.nifi.ldap.LdapProvider',
  $provider_properties = {},
  $conf_dir = $::nifi::nifi_conf_dir,
){

  $default_ldap_properties = {
    "authentication_strategy" => "START_TLS",
    "manager_DN" => "",
    "manager_password" => "",
    "TLS_-_keystore" => "",
    "TLS_-_keystore_password" => "",
    "TLS_-_keystore_type" => "",
    "TLS_-_truststore" => "",
    "TLS_-_truststore_password" => "",
    "TLS_-_truststore_type" => "",
    "TLS_-_client_auth" => "",
    "TLS_-_client_protocol" => "",
    "TLS_-_shutdown_gracefully" => "",
    "referral_strategy" => "FOLLOW",
    "connect_timeout" => "10 secs",
    "url" => "",
    "user_search_base" => "",
    "user_search_filter" => "",
    "identity_strategy" => "USE_DN",
    "authentication_expiration" => "12 hours"
  }
  $active_ldap_provider_properties = deep_merge($default_ldap_properties, $provider_properties)
  assert_type(Hash[String, String], $active_ldap_provider_properties)

  $tmp = $active_ldap_provider_properties.map |$key, $value | {
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

  $normalized_ldap_provider_properties = hash($flat_tmp)

  #notify {"$normalized_ldap_provider_properties":}

  concat::fragment { "frag_${identifier}":
    order   => '02',
    target  => "${conf_dir}/login-identity-providers.xml",
    content => template('nifi/idmapping/frag_ldap_provider.erb')
  }

  nifi::config_properties {'nifi_properties_ldap_provider':
    conf_dir => $conf_dir,
    properties => {
      'nifi.security.user.login.identity.provider' => $identifier
    }
  }
}