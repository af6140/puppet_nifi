# == Class nifi::config
#
# This class is called from nifi for service config.
#
class nifi::config {
  $nifi_properties_file = '/opt/nifi/conf/nifi.properties'
  $nifi_bootstrap_file = '/opt/nifi/conf/bootstramp.conf'

  #calculate nifi version from package version
  $pkg_version_specs = split($nifi::package_version, "-")
  $nifi_cal_version = $pkg_version_specs[0]

  notify {"version :${nifi_cal_version}":}

  assert_type(Pattern[/(\d)+\.(\d)+\.(\d)+/] ,$nifi_cal_version)



  # login provider configuration
  concat {'/opt/nifi/conf/login-identity-providers.xml':
    ensure => 'present',
    warn => true,
    owner => 'nifi',
    group => 'nifi',
    mode => '0644',
  }
  concat::fragment{ 'id_provider_start':
    order => '01',
    target => '/opt/nifi/conf/login-identity-providers.xml',
    content => "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n<loginIdentityProviders>"
  }

  concat::fragment{ 'id_provider_end':
    order => '99',
    target => '/opt/nifi/conf/login-identity-providers.xml',
    content => "</loginIdentityProviders>"
  }

  #id provider configs is optional
  if ! empty($::nifi::ldap_provider_configs) {
    nifi::ldap_provider { 'ldap_provider':
      provider_properties => $::nifi::ldap_provider_configs
    }
  }

  #config jvm size

  $minHeapArgs = "-Xms${::nifi::min_heap}"
  $maxHeapArgs = "-Xmx${::nifi::max_heap}"

  ini_setting { "nifi_bootstrap_jvm_minheap":
    ensure => present,
    path   => $nifi_bootstrap_file,
    section_prefix => '',
    section_suffix => '',
    setting => 'java.arg.2',
    value => $minHeapArgs,
  }

  ini_setting { "nifi_bootstrap_jvm_maxheap":
    ensure => present,
    path   => $nifi_bootstrap_file,
    section_prefix => '',
    section_suffix => '',
    setting => 'java.arg.3',
    value => $maxHeapArgs,
  }
  #manage state-management-xml
  concat {'/opt/nifi/conf/state-management.xml':
    ensure => 'present',
    warn => true,
    owner => 'nifi',
    group => 'nifi',
    mode => '0644',
  }
  concat::fragment{ 'state_provider_start':
    order => '01',
    target => '/opt/nifi/conf/state-management.xml',
    content => "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n<stateManagement>"
  }

  concat::fragment{ 'state_provider_end':
    order => '99',
    target => '/opt/nifi/conf/state-management.xml',
    content => "</stateManagement>"
  }
  #local provider always exists
  nifi::local_state_provider {'local_state_provider':

  }

  if $nifi::config_cluster and ! empty($::nifi::cluster_members) {
    nifi::embedded_zookeeper { "nifi_zookeeper_config":
      members => $nifi::cluster_members
    }

    $zookeeper_connect_string = join(suffix($nifi::cluster_members, ':2181'), ',')
    $nifi_cluster_configs = {
      'nifi_cluster_is_node' => 'true',
      'nifi_cluster_node_address' => $::fqdn,
      'nifi_cluster_node_protocol_port' => '9999',
      'nifi_cluster_node_event_history_size'=> '100',
      'nifi_zookeeper_connect_string' => $zookeeper_connect_string,
      'nifi_state_management_embedded_zookeeper_start' => 'true',
      'nifi_remote_input_host' => $::fqdn,
      'nifi_remote_input_socket_port' => '9998'
    }

    #cluster talkes to all embedded zookeeper
    nifi::cluster_state_provider {'cluster_state_provider':
      provider_properties => {
        'connect_string' => $zookeeper_connect_string
      }
    }
  }else {
    #disable cluster start
    $nifi_cluster_configs = {
      'nifi_cluster_is_node' => 'false',
      'nifi_state_management_embedded_zookeeper_start' => 'false',
    }

    #default cluster state provider
    nifi::cluster_state_provider {'cluster_state_provider':
    }
  }


  $tmp_active_properties = deep_merge($::nifi::params::nifi_properties, $::nifi::nifi_properties)
  $active_properties = deep_merge($tmp_active_properties, $nifi_cluster_configs)
  $active_properties.each |String $property_name, $property_value| {
    #notify {"Set setting: ${property_value}":}
    ini_setting { "nifi_setting_${$property_name}":
      ensure => present,
      path   => $nifi_properties_file,
      section_prefix => '',
      section_suffix => '',
      setting => regsubst($property_name, '_', '.', 'G'),
      value => $property_value,
    }
  }
}
