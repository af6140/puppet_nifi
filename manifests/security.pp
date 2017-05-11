# create keystore for node cert and private key, create truststore with ca cert
# keystore password : used for keystore and truststore
# key_password: the private key password
define nifi::security(
  $cacert = undef,
  $node_cert = undef,
  $node_private_key = undef,
  $initial_admin_cert = undef,
  $initial_admin_key = undef,
  $keystore_password = 'changeit',
  $key_password = undef,
  $client_auth = false,
){


  assert_type(String[1], $cacert)
  assert_type(String[1], $node_cert)
  assert_type(String[1], $node_private_key)
  assert_type(String[1], $initial_admin_cert)
  assert_type(String[6], $keystore_password)

  #validate_x509_rsa_key_pari($node_cert, $node_private_key)

  file {"${::nifi::nifi_conf_dir}/certs":
    ensure => 'directory',
    owner => 'nifi',
    group => 'nifi',
    mode => '0644',
  } ->
  file {"${::nifi::nifi_conf_dir}/keys":
    ensure => 'directory',
    owner => 'nifi',
    group => 'nifi',
    mode => '0600',
  }
  file {"${::nifi::nifi_conf_dir}/certs/ca.pem":
    ensure => 'present',
    owner => 'nifi',
    group => 'nifi',
    mode => '0644',
    content => $cacert,
    require => File["${::nifi::nifi_conf_dir}/certs"]
  }
  file {"${::nifi::nifi_conf_dir}/certs/${::fqdn}.pem":
    ensure => 'present',
    owner => 'nifi',
    group => 'nifi',
    mode => '0644',
    content => $node_cert,
    require => File["${::nifi::nifi_conf_dir}/certs"]
  }
  file {"/opt/nifi/conf/keys/${::fqdn}_private.key":
    ensure => 'present',
    owner => 'nifi',
    group => 'nifi',
    mode => '0600',
    content => $node_private_key,
    require => File["${::nifi::nifi_conf_dir}/keys"]
  }

  file { "/opt/nifi/conf/certs/${::fqdn}_initial_admin.pem":
    ensure => 'present',
    owner => 'nifi',
    group => 'nifi',
    mode => '0644',
    content => $initial_admin_cert,
    require => File["${::nifi::nifi_conf_dir}/certs"]
  }
  file { "/opt/nifi/conf/keyss/${::fqdn}_initial_admin.key":
    ensure => 'present',
    owner => 'nifi',
    group => 'nifi',
    mode => '0600',
    content => $initial_admin_key,
    require => File["${::nifi::nifi_conf_dir}/keys"]
  }

  java_ks {'nifi_truststore:ca':
    ensure => latest,
    certificate => '/opt/nifi/conf/certs/ca.pem',
    target => '/opt/nifi/conf/truststore.jks',
    trustcacerts => true,
    password => $keystore_password,
    require => File["${::nifi::nifi_conf_dir}/certs/ca.pem"],
  }
  java_ks {"nifi_keystore:${fqdn}":
    ensure => latest,
    target => "${::nifi::nifi_conf_dir}/keystore.jks",
    certificate => "${::nifi::nifi_conf_dir}/certs/${::fqdn}.pem",
    private_key => "${::nifi::nifi_conf_dir}/keys/${::fqdn}_private.pem",
    password => $keystore_password,
    destkeypass => $key_password,
    require => File["${::nifi::nifi_conf_dir}/keys/${::fqdn}_private.key", "${::nifi::nifi_conf_dir}/certs/${::fqdn}.pem"]
  }

  ini_setting { "nifi_setting_nifi_security_keystore":
    ensure => present,
    path   => "${::nifi::nifi_conf_dir}/nifi.properties",
    section_prefix => '',
    section_suffix => '',
    setting => 'nifi.security.keystore',
    value => '/opt/nifi/conf/keystore.jks'
  }
  ini_setting { "nifi_setting_nifi_security_keystoreType":
    ensure => present,
    path   => "${::nifi::nifi_conf_dir}/nifi.properties",
    section_prefix => '',
    section_suffix => '',
    setting => 'nifi.security.keystoreType',
    value => 'jks'
  }
  ini_setting { "nifi_setting_nifi_security_keystorePasswd":
    ensure => present,
    path   => "${::nifi::nifi_conf_dir}/nifi.properties",
    section_prefix => '',
    section_suffix => '',
    setting => 'nifi.security.keystorePasswd',
    value => $keystore_password
  }
  ini_setting { "nifi_setting_nifi_security_keyPasswd":
    ensure => present,
    path   => "${::nifi::nifi_conf_dir}/nifi.properties",
    section_prefix => '',
    section_suffix => '',
    setting => 'nifi.security.keyPasswd',
    value => $key_password,
  }

  ini_setting { "nifi_setting_nifi_security_truststore":
    ensure => present,
    path   => "${::nifi::nifi_conf_dir}/nifi.properties",
    section_prefix => '',
    section_suffix => '',
    setting => 'nifi.security.truststore',
    value => '/opt/nifi/conf/truststore.jks'
  }
  ini_setting { "nifi_setting_nifi_security_truststoreType":
    ensure => present,
    path   => "${::nifi::nifi_conf_dir}/nifi.properties",
    section_prefix => '',
    section_suffix => '',
    setting => 'nifi.security.truststoreType',
    value => 'jks'
  }
  ini_setting { "nifi_setting_nifi_security_truststorePasswd":
    ensure => present,
    path   => "${::nifi::nifi_conf_dir}/nifi.properties",
    section_prefix => '',
    section_suffix => '',
    setting => 'nifi.security.truststorePasswd',
    value => $keystore_password
  }

  ini_setting { "nifi_setting_nifi_security_needClientAuth":
    ensure => present,
    path   => "${::nifi::nifi_conf_dir}/nifi.properties",
    section_prefix => '',
    section_suffix => '',
    setting => 'nifi.security.needClientAuth',
    value => $client_auth
  }
}