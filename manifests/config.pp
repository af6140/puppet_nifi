# == Class nifi::config
#
# This class is called from nifi for service config.
#
class nifi::config(
) {

  #calculate nifi version from package version
  $pkg_version_specs = split($nifi::package_version, "-")
  $nifi_cal_version = $pkg_version_specs[0]

  notify {"version :${nifi_cal_version}":}

  #assert_type(Pattern[/(\d)+\.(\d)+\.(\d)+/] ,$nifi_cal_version)



  ##bootstrap jvm customization
  #config jvm size

  $minHeapArgs = "-Xms${::nifi::min_heap}"
  $maxHeapArgs = "-Xmx${::nifi::max_heap}"

  $bootstrap_properties = {
    'java.arg.2' => $minHeapArgs,
    'java.arg.3' => $maxHeapArgs,
    'java.arg.8' => "-XX:CodeCacheMinimumFreeSpace=10m",
    'java.arg.9' => "-XX:+UseCodeCacheFlushing",
  }

  nifi::bootstrap_properties { 'bootstrap_jvm_conf':
    properties => $bootstrap_properties
  }

  # login provider configuration
  concat {'/opt/nifi/conf/login-identity-providers.xml':
    ensure => 'present',
    warn => true,
    owner => 'nifi',
    group => 'nifi',
    mode => '0644',
    ensure_newline => true,
  }
  concat::fragment{ 'id_provider_start':
    order => '01',
    target => '/opt/nifi/conf/login-identity-providers.xml',
    content => "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n<loginIdentityProviders>\n"
  }

  concat::fragment{ 'id_provider_end':
    order => '99',
    target => '/opt/nifi/conf/login-identity-providers.xml',
    content => "\n</loginIdentityProviders>"
  }

  #id provider configs is optional
  if ! empty($::nifi::ldap_provider_configs) {
    nifi::ldap_provider { 'ldap_provider':
      provider_properties => $::nifi::ldap_provider_configs
    }
  }


  #manage ldap id mapping

  if ! empty($nifi::id_mappings) {
    #use index 0 to override default pattern
    $nifi::id_mappings.each |$index, $entry| {
      $conf_index = $entry['index']
      $conf_ensure = $entry['ensure']
      if $conf_index {
        $real_index = $conf_index
      }else {
        $real_index = $index
      }

      if $conf_ensure {
        $real_ensure = $conf_ensure
      }else {
        $real_ensure = 'present'
      }
      nifi::idmapping_dn { "ldap_id_mapping_${index}":
        pattern => $entry['pattern'],
        value => $entry['value'],
        index => $real_index,
        ensure => $real_ensure
      }
    }
  }
  #manage state-management-xml
  concat {'/opt/nifi/conf/state-management.xml':
    ensure => 'present',
    warn => true,
    owner => 'nifi',
    group => 'nifi',
    mode => '0644',
    ensure_newline => true,
  }
  concat::fragment{ 'state_provider_start':
    order => '01',
    target => '/opt/nifi/conf/state-management.xml',
    content => "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n<stateManagement>\n"
  }

  concat::fragment{ 'state_provider_end':
    order => '99',
    target => '/opt/nifi/conf/state-management.xml',
    content => "\n</stateManagement>"
  }
  #local provider always exists
  nifi::local_state_provider {'local_state_provider':

  }

  if $nifi::config_cluster and ! empty($::nifi::cluster_members) {
    nifi::embedded_zookeeper { "nifi_zookeeper_config":
      members => $nifi::cluster_members
    }

    $zookeeper_connect_string = join(suffix($nifi::cluster_members, ':2181'), ',')

    #cluster talkes to all embedded zookeeper
    nifi::cluster_state_provider {'cluster_state_provider':
      provider_properties => {
        'connect_string' => $zookeeper_connect_string
      }
    }

    if ! $zookeeper_connect_string {
      $real_zookeeper_connect_string =''
    }else {
      $real_zookeeper_connect_string = $zookeeper_connect_string
    }

    $nifi_cluster_configs = {
      'nifi.cluster.is.node' => 'true',
      'nifi.cluster.node.address' => $::fqdn,
      'nifi.cluster.node.protocol.port' => '9999',
      'nifi.cluster.node.event.history.size'=> '100',
      'nifi.zookeeper.connect.string' => $real_zookeeper_connect_string,
      'nifi.state.management.embedded.zookeeper.start' => 'true',
      'nifi.remote.input.host' => $::fqdn,
      'nifi.remote.input.socket.port' => '9998'
    }

    #need set cluster memeber node identity in authorizers.xml
    #this really depends on the id mapping rule
    # for example, can use
    $cluster_dns = $nifi::cluster_identities.map |$index, $node_identity| {
      $real_index = $index+1
      ["node_identity_${real_index}", $node_identity]
    }

    #notify {"$cluster_dns":}
    $cluster_ids_hash = hash(flatten($cluster_dns))

  }else {
    #disable cluster start
    $nifi_cluster_configs = {
      'nifi.cluster.is.node' => 'false',
      'nifi.zookeeper.connect.string' => '',
      'nifi.state.management.embedded.zookeeper.start' => 'false',
    }

    #default cluster state provider
    nifi::cluster_state_provider {'cluster_state_provider':
    }

    $cluster_ids_hash = {}
  }


  $active_properties = deep_merge($::nifi::params::nifi_properties, $::nifi::nifi_properties, $nifi_cluster_configs)
  # $active_properties.each |String $property_name, $property_value| {
  #   #notify {"Set setting: ${property_value}":}
  #   ini_setting { "nifi_setting_${$property_name}":
  #     ensure => present,
  #     path   => "${::nifi::nifi_conf_dir}/nifi.properties",
  #     section_prefix => '',
  #     section_suffix => '',
  #     setting => regsubst($property_name, '_', '.', 'G'),
  #     value => $property_value,
  #   }
  # }
  notify {"$active_properties": }
  nifi::config_properties {'nifi_general_configs':
    properties => $active_properties
  }
  #manage authorizer
  concat {'/opt/nifi/conf/authorizers.xml':
    ensure => 'present',
    warn => true,
    owner => 'nifi',
    group => 'nifi',
    mode => '0644',
    ensure_newline => true,
  }
  concat::fragment{ 'authorizers_start':
    order => '01',
    target => '/opt/nifi/conf/authorizers.xml',
    content => "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n<authorizers>"
  }

  concat::fragment{ 'authorizers_end':
    order => '99',
    target => '/opt/nifi/conf/authorizers.xml',
    content => "\n</authorizers>"
  }

  if $::nifi::config_ssl{

    if ! $::nifi::initial_admin_identity or empty($::nifi::initial_admin_identity) {
      fail("When setup secure nifi instance, initial admin identity is required")
    }

    $admin_id_hash = {
      'initial_admin_identity' => $::nifi::initial_admin_identity
    }

    #if configure cluster, add node identities to authorizers.xml
    $authorizer_props = deep_merge($admin_id_hash, $cluster_ids_hash)

    nifi::file_authorizer { 'nifi_file_authorizer':
      provider_properties => $authorizer_props
    }
    nifi::security { 'nifi_properties_security_setting':
      cacert_path             => $::nifi::cacert_path,
      node_cert_path          => $::nifi::node_cert_path,
      node_private_key_path   => $::nifi::node_private_key_path,
      initial_admin_cert_path => $::nifi::initial_admin_cert_path,
      initial_admin_key_path  => $::nifi::initial_admin_key_path,
      keystore_password  => $::nifi::keystore_password,
      key_password       => $::nifi::key_password,
      client_auth        => $::nifi::client_auth,
    }
  }else {
    #default file authorizer
    nifi::file_authorizer { 'nifi_file_authorizer':
    }
  }


  nifi::custom_properties{'nifi_custom_properties':

  }
}
