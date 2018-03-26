# == Class nifi::config
#
# This class is called from nifi for service config.
#
class nifi::config(
) {

  #calculate nifi version from package version
  $pkg_version_specs = split($nifi::package_version, "-")
  $nifi_cal_version = $pkg_version_specs[0]

  ##bootstrap jvm customization
  #config jvm size

  $minHeapArgs = "-Xms${::nifi::min_heap}"
  $maxHeapArgs = "-Xmx${::nifi::max_heap}"

  if $::nifi::enable_jolokia and $::nifi::jolokia_agent_path {
    file { "${::nifi::nifi_conf_dir}/jolokia_access.xml":
      ensure => 'present',
      owner => 'nifi',
      group => 'nifi',
      content => template('nifi/jolokia_access.xml.erb')
    }
    $properties_require = [File["${::nifi::nifi_conf_dir}/jolokia_access.xml"]]
    $bootstrap_properties = {
      'java.arg.2' => $minHeapArgs,
      'java.arg.3' => $maxHeapArgs,
      'java.arg.8' => "-XX:CodeCacheMinimumFreeSpace=10m",
      'java.arg.9' => "-XX:+UseCodeCacheFlushing",
      'java.arg.13'=> '-XX:+UseG1GC',
      'java.arg.11'=> "-javaagent:${::nifi::jolokia_agent_path}=config=${::nifi::nifi_conf_dir}/jolokia_access.xml"
    }
  }else {
    $bootstrap_properties = {
      'java.arg.2' => $minHeapArgs,
      'java.arg.3' => $maxHeapArgs,
      'java.arg.8' => "-XX:CodeCacheMinimumFreeSpace=10m",
      'java.arg.9' => "-XX:+UseCodeCacheFlushing",
      'java.arg.13'=> '-XX:+UseG1GC',
    }
    $properties_require = []
  }

  nifi::bootstrap_properties { 'bootstrap_jvm_conf':
    properties => $bootstrap_properties
  }

  # login provider configuration
  concat {"${::nifi::nifi_conf_dir}/login-identity-providers.xml":
    ensure => 'present',
    warn => false,
    owner => 'nifi',
    group => 'nifi',
    mode => '0644',
    ensure_newline => true,
    notify => $::nifi::service_notify,
  }
  concat::fragment{ 'id_provider_start':
    order => '01',
    target => "${::nifi::nifi_conf_dir}/login-identity-providers.xml",
    content => "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n<!--\nThis file is managed by Puppet. DO NOT EDIT\n-->\n<loginIdentityProviders>\n"
  }

  concat::fragment{ 'id_provider_end':
    order => '99',
    target => "${::nifi::nifi_conf_dir}/login-identity-providers.xml",
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
        ensure => $real_ensure,
        notify => $::nifi::service_notify,
      }
    }
  }
  #manage state-management-xml
  concat {"${::nifi::nifi_conf_dir}/state-management.xml":
    ensure => 'present',
    warn => false,
    owner => 'nifi',
    group => 'nifi',
    mode => '0644',
    ensure_newline => true,
    notify => $::nifi::service_notify,
  }
  concat::fragment{ 'state_provider_start':
    order => '01',
    target => "${::nifi::nifi_conf_dir}/state-management.xml",
    content => "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n<!--\nThis file is managed by Puppet. DO NOT EDIT\n-->\n<stateManagement>\n"
  }

  concat::fragment{ 'state_provider_end':
    order => '99',
    target => "${::nifi::nifi_conf_dir}/state-management.xml",
    content => "\n</stateManagement>"
  }
  #local provider always exists
  nifi::local_state_provider {'local_state_provider':

  }

  if $nifi::config_cluster and ! empty($::nifi::cluster_members) {
    $real_config_cluster = true
    nifi::embedded_zookeeper { "nifi_zookeeper_config":
      members => $nifi::cluster_members,
      ids => $nifi::cluster_zookeeper_ids,
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

    if $::nifi::flow_election_max_candidates and $::nifi::flow_election_max_candidates >=2 {
      $max_candidates = $::nifi::flow_election_max_candidates
    }else {
      $max_candidates = 2
    }
    $nifi_cluster_configs = {
      'nifi.cluster.is.node' => 'true',
      'nifi.cluster.node.address' => $::fqdn,
      'nifi.cluster.node.protocol.port' => '9999',
      'nifi.cluster.node.event.history.size'=> '100',
      'nifi.zookeeper.connect.string' => $real_zookeeper_connect_string,
      'nifi.state.management.embedded.zookeeper.start' => 'true',
      'nifi.remote.input.host' => $::fqdn,
      'nifi.remote.input.socket.port' => '9998',
      'nifi.cluster.flow.election.max.candidates' => $max_candidates,
      'nifi.cluster.flow.election.max.wait.time' => '3 mins',
    }

    #need set cluster memeber node identity in authorizers.xml
    #this really depends on the id mapping rule
    # for example, can use
    $cluster_dns = $nifi::cluster_identities.map |$index, $node_identity| {
      $real_index = $index+1
      ["node_identity_${real_index}", $node_identity]
    }

    $cluster_ids_hash = hash(flatten($cluster_dns))

  }else {
    #disable cluster start
    $real_config_cluster = false
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

  $tmp_config_properties = $::nifi::nifi_properties.map |$key, $value | {
    #replace  _ with '.'
    $keyspecs = split($key, '_')
    $prop_key = join($keyspecs, '.')
    [$prop_key, $value]
  }

  $tmp_provenance_properties = {
    'nifi.provenance.repository.max.storage.time'=> $nifi::provenance_storage_time,
    'nifi.provenance.repository.max.storage.size' => $nifi::provenance_storage_size,
  }

  $normaized_config_properties = hash(flatten($tmp_config_properties))


  #directories location

  $file_location_properties = {
    'nifi.flow.configuration.file' => "${::nifi::nifi_flow_dir}/flow.xml.gz",
    'nifi.templates.directory'=> "${::nifi::nifi_flow_dir}/templates",
    'nifi.variable.registry.properties' => "${::nifi::nifi_flow_dir}/custom.properties",
    'nifi.flow.configuration.archive.dir' => "${::nifi::nifi_conf_dir}/archive/",
    'nifi.authorizer.configuration.file' => "${::nifi::nifi_conf_dir}/authorizers.xml",
    'nifi.login.identity.provider.configuration.file ' => "${::nifi::nifi_conf_dir}/login-identity-providers.xml",
    'nifi.state.management.configuration.file' => "${::nifi::nifi_conf_dir}/state-management.xml",
    'nifi.state.management.embedded.zookeeper.properties' => "${::nifi::nifi_conf_dir}/zookeeper.properties",
    'nifi.nar.working.directory' => "${::nifi::nifi_work_dir}/nar/",
    'nifi.documentation.working.directory' => "${::nifi::nifi_work_dir}/docs/components",
    'nifi.web.jetty.working.directory' => "${::nifi::nifi_work_dir}/jetty"
  }

  $active_properties = deep_merge($::nifi::params::nifi_properties, $tmp_provenance_properties,  $normaized_config_properties, $file_location_properties, $nifi_cluster_configs)

  #Generate configuration file
  #notify { "general config: ${active_properties}":}
  nifi::config_properties {'nifi_general_configs':
    properties => $active_properties,
    require => $properties_require,
  }
  #manage authorizer
  concat {"${::nifi::nifi_conf_dir}/authorizers.xml":
    ensure => 'present',
    warn => false,
    owner => 'nifi',
    group => 'nifi',
    mode => '0644',
    ensure_newline => true,
    notify => $::nifi::service_notify,
  }
  concat::fragment{ 'authorizers_start':
    order => '01',
    target => "${::nifi::nifi_conf_dir}/authorizers.xml",
    content => "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n<!--\nThis file is managed by Puppet. DO NOT EDIT\n-->\n<authorizers>"
  }

  concat::fragment{ 'authorizers_end':
    order => '99',
    target => "${::nifi::nifi_conf_dir}/authorizers.xml",
    content => "\n</authorizers>"
  }

  #ssl
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
      config_cluster => $real_config_cluster,
      client_auth => $::nifi::client_auth
    }
  }else {
    #no ssl, no authorization, no security
    #default file authorizer
    nifi::file_authorizer { 'nifi_file_authorizer':
    }

    #configure default security, no ssl, no initial admin no client auth
    #no cluster communication authentication/security
    nifi::security { 'nifi_properties_security_setting':
      config_cluster => $real_config_cluster,
      client_auth => false,
    }
  }

  nifi::custom_properties{'nifi_custom_properties':

  }

  if $::nifi::systemd_overrides and ! empty($::nifi::systemd_overrides) {
    $systemd_overrides = $::nifi::systemd_overrides
    file { '/etc/systemd/system/nifi.service.d/nifi.conf':
      ensure => 'present',
      content => template('nifi/service/service_override.erb'),
    }
  }else {
    file { "/etc/systemd/system/nifi.service.d/nifi.conf":
      ensure => 'absent',
    }
  }
}
