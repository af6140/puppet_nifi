# Class: nifi
# ===========================
#
# Full description of class nifi here.
#
# Parameters
# ----------
#
# * `sample parameter`
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
class nifi (
  String[1] $package_name = $::nifi::params::package_name,
  String[1] $service_name = $::nifi::params::service_name,
  String[1] $package_version = $::nifi::params::package_version,
  String[1] $nifi_home = $::nifi::params::nifi_home,
  String[1] $nifi_conf_dir = $::nifi::params::nifi_conf_dir,
  String[1] $nifi_flow_dir = $::nifi::params::nifi_flow_dir,
  String[1] $nifi_work_dir = $::nifi::params::nifi_work_dir,
  Optional[Hash[String[1],String[1]]] $nifi_properties = {},
  $min_heap = '512m',
  $max_heap = '512m',
  Boolean $config_cluster = false,
  Optional[Array[String[1]]] $cluster_members = [],
  Optional[Array[String[1]]] $cluster_identities=[],
  Optional[Array[Integer[1,255]]] $cluster_zookeeper_ids =[],
  Hash[String[1],String[1]] $ldap_provider_configs = {},
  Optional[Array[Struct[{pattern => String[1], value=>String[1], ensure => Optional[Enum[present,absent]], index => Optional[Integer[0,9]] }],0,9]] $id_mappings = undef,
  Boolean $config_ssl=true,
  Optional[String[1]] $initial_admin_identity = $::nifi::params::initial_admin_identity,
  Optional[String[1]] $cacert_path = undef,
  Optional[String[1]] $node_cert_path = undef,
  Optional[String[1]] $node_private_key_path = undef,
  Optional[String[1]] $initial_admin_cert_path = undef,
  Optional[String[1]] $initial_admin_key_path = undef,
  String[6] $keystore_password = 'changeit',
  Optional[String[6]] $key_password = undef,
  Boolean $client_auth = false,
  Optional[String[1]] $custom_properties_file = $::nifi::params::custom_properties_file,
  Optional[Hash[String[1],String[1]]] $custom_properties = undef,
  Optional[Integer[2,99]] $flow_election_max_candidates = $::nifi::params::flow_election_max_candidates,
  Integer[1024] $web_http_port = $::nifi::params::web_http_port,
  Integer[1024] $web_https_port = $::nifi::params::web_https_port,
  String[1] $provenance_storage_time = "24 hours",
  String[1] $provenance_storage_size = "1 GB"
) inherits ::nifi::params {

  package {'rubygem-rest-client':
    ensure => 'present'
  }


  if($config_cluster) {
    $count_of_nodes = size($cluster_members)
    $count_of_identities = size($cluster_identities)

    if  $count_of_nodes != $count_of_identities {
      fail("Count of nodes does not match count of node identities")
    }

    if ! $config_ssl  {
      fail("when configuring secure cluster, ssl must be configured, since node use cert for identity")
    }
  }

  class { '::nifi::install': } ->
  class { '::nifi::config': } ~>
  class { '::nifi::service': } ->
  Class['::nifi']


  file {"${::nifi::nifi_conf_dir}/logback.xml":
    ensure => 'present',
    mode => '644',
    owner => 'nifi',
    group => 'nifi',
    content => template('nifi/logback.xml.erb'),
    require => Package['nifi'],
  }

  #static configuration facts
  file {'/etc/facter/facts.d/nifi.txt':
    ensure => 'present',
    owner => 'root',
    group => 'root',
    mode => '0644'
  } ->
  nifi::extfact{'nifi_home':
    key => 'nifi_home',
    value => $::nifi::nifi_home
  }->
  nifi::extfact{'nifi_conf_dir':
    key => 'nifi_conf_dir',
    value => $::nifi::nifi_conf_dir
  }->
  nifi::extfact{'nifi_flow_dir':
    key => 'nifi_flow_dir',
    value => $::nifi::nifi_flow_dir
  }->
  nifi::extfact{'nifi_initial_admin_cert':
    key => 'nifi_initial_admin_cert_path',
    value => $::nifi::initial_admin_cert_path
  }->
  nifi::extfact{'nifi_initial_admin_key':
    key => 'nifi_initial_admin_key_path',
    value => $::nifi::initial_admin_key_path
  }
}
