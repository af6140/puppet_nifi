# Configure seucrity/ssl and secure communication between clsuter and site-to-site traffic
#
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
  Boolean $client_auth = $::nifi::client_auth,
  Boolean $config_cluster,
){

  # site to site communication has two protocols
  # one is raw, the other is http based
  # nifi.remote.input.socket.* are RAW transport protocol specific. Similarly, nifi.remote.input.http.* are HTTP transport protocol specific properties.
  # nifi.remote.input.secure determines whether site-to-site communication through is https or http
  #
  # when nifi.security.needClientAuth is set to true, this is to secure/authenticate client for cluster protocol, the cluster communication must be
  # secured(nifi.cluster.protocol.is.secure=true), since the only way to identity the node identity is through node certificates
  #
  if $initial_admin_cert_path and $cacert_path and $initial_admin_key_path and $node_cert_path and $node_private_key_path and $keystore_password {
    validate_absolute_path($cacert_path)
    validate_absolute_path($node_cert_path)
    validate_absolute_path($node_private_key_path)
    validate_absolute_path($initial_admin_cert_path)
    validate_absolute_path($initial_admin_key_path)


    java_ks { 'nifi_truststore:ca':
      ensure       => latest,
      certificate  => $cacert_path,
      target       => '/opt/nifi/conf/truststore.jks',
      trustcacerts => true,
      password     => $keystore_password
    }
    java_ks { "nifi_keystore:${fqdn}":
      ensure      => latest,
      target      => "${::nifi::nifi_conf_dir}/keystore.jks",
      certificate => $node_cert_path,
      private_key => $node_private_key_path,
      password    => $keystore_password,
      destkeypass => $key_password,
    }

    # check cluster protocol is secure
    if $config_cluster and $client_auth {
      $cluster_protocol_secure = true
    }else {
      $cluster_protocol_secure = false
    }
    notify{'ssl security configured':
      message => "client auth enabled =${client_auth},  cluster config enabled = ${config_cluster}, cluster secure protocol=${cluster_protocol_secure}, web https disabled, http enabled",
      noop=>true
    }
    #disable http port
    $security_properties = {
      'nifi.security.keystore'          => '/opt/nifi/conf/keystore.jks',
      'nifi.security.keystoreType'      => 'jks',
      'nifi.security.keystorePasswd'    => $keystore_password,
      'nifi.security.keyPasswd'         => $key_password,
      'nifi.security.truststore'        => '/opt/nifi/conf/truststore.jks',
      'nifi.security.truststorePasswd'  => $keystore_password,
      'nifi.security.truststoreType'    => 'jks',
      'nifi.security.needClientAuth'    => "${client_auth}",
      'nifi.web.http.port'              => '',
      'nifi.web.https.port'              => "${::nifi::web_https_port}",
      'nifi.cluster.protocol.is.secure' => "${cluster_protocol_secure}",
      'nifi.remote.input.secure'        => 'true',
    }
    nifi::config_properties { 'nifi_security_props':
      properties => $security_properties
    }
  }else {
    notify{'no ssl security configured':
      message => 'client auth disabled for cluster communication, cluster protocol is not secure, web https disabled, http enabled',
      noop => true,
    }
    $security_properties = {
      'nifi.security.keystore'          => '',
      'nifi.security.keystoreType'      => '',
      'nifi.security.keystorePasswd'    => '',
      'nifi.security.keyPasswd'         => '',
      'nifi.security.truststore'        => '',
      'nifi.security.truststorePasswd'  => '',
      'nifi.security.truststoreType'    => '',
      'nifi.security.needClientAuth'    => 'false',
      'nifi.cluster.protocol.is.secure' => 'false',
      'nifi.remote.input.secure'        => 'false',
      'nifi.web.http.port'              => "${::nifi::web_http_port}",
      'nifi.web.https.port'              => '',
    }
    nifi::config_properties { 'nifi_security_props':
      properties => $security_properties
    }
  }
}