# == Class nifi::service
#
# This class is meant to be called from nifi.
# It ensure the service is running.
#
class nifi::service {
  service { $::nifi::service_name:
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }
}
