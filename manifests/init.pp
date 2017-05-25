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
  $service_name = $::nifi::params::service_name,
  $package_version = $::nifi::params::package_version,
  String[1] $nifi_home = $::nifi::params::nifi_home,
  String[1] $nifi_conf_dir = $::nifi::params::nifi_conf_dir,
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
) inherits ::nifi::params {


  notify{"initial admin identity: ${initial_admin_identity}":
    message => "${initial_admin_identity}",
    noop => true,
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
}
