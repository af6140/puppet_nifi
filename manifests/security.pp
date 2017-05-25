# create keystore for node cert and private key, create truststore with ca cert
# keystore password : used for keystore and truststore
# key_password: the private key password
define nifi::security(
  $cacert_path = undef,
  $node_cert_path = undef,
  $node_private_key_path = undef,
  $initial_admin_cert_path = undef,
  $initial_admin_key_path = undef,
  $keystore_password = 'changeit',
  $key_password = undef,
  $client_auth = false,
){



  validate_absolute_path($cacert_path)
  validate_absolute_path($node_cert_path)
  validate_absolute_path($node_private_key_path)
  validate_absolute_path($initial_admin_cert_path)
  validate_absolute_path($initial_admin_key_path)


  java_ks {'nifi_truststore:ca':
    ensure => latest,
    certificate => $cacert_path,
    target => '/opt/nifi/conf/truststore.jks',
    trustcacerts => true,
    password => $keystore_password
  }
  java_ks {"nifi_keystore:${fqdn}":
    ensure => latest,
    target => "${::nifi::nifi_conf_dir}/keystore.jks",
    certificate => $node_cert_path,
    private_key => $node_private_key_path,
    password => $keystore_password,
    destkeypass => $key_password,
  }

  #disable http port
  $security_properties = {
    'nifi.security.keystore'=>'/opt/nifi/conf/keystore.jks',
    'nifi.security.keystoreType' => 'jks',
    'nifi.security.keystorePasswd' => $keystore_password,
    'nifi.security.keyPasswd' => $key_password,
    'nifi.security.truststore' => '/opt/nifi/conf/truststore.jks',
    'nifi.security.truststorePasswd' => $keystore_password,
    'nifi.security.truststoreType' => 'jks',
    'nifi.security.needClientAuth' => $client_auth,
    'nifi.web.http.port' => '',
    'nifi.remote.input.secure' => 'true',
  }
  nifi::config_properties {'nifi_security_props':
    properties => $security_properties
  }
}