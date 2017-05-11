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
  $nifi_properties = {},
  $min_heap = '512m',
  $max_heap = '512m',
  $config_cluster = false,
  $cluster_members = [],
  $ldap_provider_configs = {}
) inherits ::nifi::params {

  # validate parameters here

  class { '::nifi::install': } ->
  class { '::nifi::config': } ~>
  class { '::nifi::service': } ->
  Class['::nifi']
}
