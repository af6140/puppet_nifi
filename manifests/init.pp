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
  $package_name = $::nifi::params::package_name,
  $service_name = $::nifi::params::service_name,
  $package_version = $::nifi::params::package_version,
  $nifi_conf_dir = $::nifi::params::nifi_conf_dir,
  $nifi_properties = {},
  $min_heap = '512m',
  $max_heap = '512m',
  $config_cluster = false,
  $cluster_members = [],
  $cluster_identities=[],
  $ldap_provider_configs = {},
  $ldap_id_mappings = undef,
  $config_ssl=false,
  $initial_admin_identity = undef,
  $cacert = undef,
  $node_cert = undef,
  $node_private_key = undef,
  $initial_admin_cert = undef,
  $initial_admin_key = undef,
  $keystore_password = 'changeit',
  $key_password = undef,
  $client_auth = false,
  $custom_properties_file = $::nifi::params::custom_properties_file,
  $custom_properties = undef,
) inherits ::nifi::params {

  # validate parameters here

  assert_type(String[1], $package_name)
  assert_type(String[1], $package_version)

  assert_type(Boolean, $config_cluster)
  assert_type(Boolean, $config_ssl)

  if $cluster_members {
    assert_type(Array, $cluster_members)
  }

  if $ldap_id_mappings {
    assert_type(Array[Hash[String, String], 0, 99], $ldap_id_mappings)
  }

  if($config_cluster) {
    $count_of_nodes = size($cluster_members)
    $count_of_identities = size($cluster_identities)

    if  $count_of_nodes != $count_of_identities {
      fail("Count of nodes does not match count of node identities")
    }
  }

  class { '::nifi::install': } ->
  class { '::nifi::config': } ~>
  class { '::nifi::service': } ->
  Class['::nifi']

  Ini_setting<| |> ~> Service['nifi']
}
