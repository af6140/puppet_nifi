# == Class nifi::service
#
# This class is meant to be called from nifi.
# It ensure the service is running.
#
class nifi::service {
  if $::nifi::start_service {
    service { $::nifi::service_name:
      ensure     => running,
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
    }
  }else {
    exec {"enable_${::nifi::service_name}":
      path => '/bin:/sbin:/usr/bin:/usr/sbin',
      command => "systemctl enable ${::nifi::service_name}",
      unless => ["systemctl is-enabled ${::nifi::service_name}"]
    }
  }
}
