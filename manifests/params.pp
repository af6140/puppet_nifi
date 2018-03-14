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
      $package_version = 'present'
      $nifi_home = '/opt/nifi'
      $nifi_conf_dir = '/opt/nifi/conf'
      $nifi_flow_dir = '/opt/nifi/flow'
      $nifi_work_dir = '/opt/nifi/work'
      $custom_properties_file = '/opt/nifi/flow/custom.properties'
    }
    default: {
      fail("${::operatingsystem} not supported")
    }
  }
  $initial_admin_identity = 'nifi-admin'
  $web_http_port = 8080
  $web_https_port = 8443

  # core properties https://community.hortonworks.com/articles/7882/hdfnifi-best-practices-for-setting-up-a-high-perfo.html
  $nifi_properties ={
    'nifi.flow.configuration.file' => '/opt/nifi/flow/flow.xml.gz',
    'nifi.flow.configuration.archive.dir' => '/opt/nifi/conf/archive/',
    'nifi.flow.configuration.archive.enabled' => 'true',
    'nifi.flow.configuration.archive.max.time' => '30 days',
    'nifi.templates.directory'=> '/opt/nifi/flow/templates',
    'nifi.variable.registry.properties' => '/opt/nifi/flow/custom.properties',
    'nifi.web.http.host' => $::fqdn,
    'nifi.web.https.host' => $::fqdn,
    'nifi.security.user.authorizer' => 'file-provider',
    'nifi.cluster.is.node' => 'false',
    'nifi.authorizer.configuration.file' => '/opt/nifi/conf/authorizers.xml',
    'nifi.login.identity.provider.configuration.file ' => '/opt/nifi/conf/login-identity-providers.xml',
    'nifi.state.management.configuration.file' => '/opt/nifi/conf/state-management.xml',
    'nifi.state.management.embedded.zookeeper.properties' => '/opt/nifi/conf/zookeeper.properties',
    'nifi.nar.working.directory' => '/opt/nifi/work/nar/',
    'nifi.documentation.working.directory' => '/opt/nifi/work/docs/components',
    'nifi.web.jetty.working.directory' => '/opt/nifi/work/jetty',
    'nifi.flowcontroller.graceful.shutdown.period' => '20 sec',
    'nifi.bored.yield.duration' => '30 millis',
    'nifi.administrative.yield.duration' => '30 sec',
    'nifi.flowservice.writedelay.interval' => '500 ms'
  }
  $flow_election_max_candidates = 2

}
