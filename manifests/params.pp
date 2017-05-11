# == Class nifi::params
#
# This class is meant to be called from nifi.
# It sets variables according to platform.
#
class nifi::params {
  case $::osfamily {
    'RedHat', 'Amazon': {
      $package_name = 'nifi'
      $service_name = 'nifi'
      $package_version = '1.2.0-0.noarch'
    }
    default: {
      fail("${::operatingsystem} not supported")
    }
  }
  $nifi_properties ={
    nifi_flow_configuration_file => '/opt/nifi/flow/flow.xml.gz',
    nifi_templates_directory=> '/opt/nifi/flow/templates',
    nifi_variable_registry_properties => ['/opt/nifi/flow/custom.properties'],
    nifi_web_http_port => '8080',
    nifi_web_http_host => $::fqdn,
    nifi_web_https_host => $::fqdn,
    nifi_web_http_network_interface_default => '',
    nifi_security_user_uthorizer => 'file-provider',
    nifi_cluster_is_node => 'false',
  }
}
