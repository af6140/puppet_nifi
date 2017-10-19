define nifi::config_properties (
  $conf_dir = $::nifi::nifi_conf_dir,
  $properties = {}
){
  assert_type(Hash[String,Scalar], $properties)
  $path = "${conf_dir}/nifi.properties"

  if ! empty($properties) {
    $changes = $properties.map |String $key, Scalar $value| {
      "set ${key} '${value}'"
    }
    augeas {"update-nifi-properties-${title}":
      lens => 'Properties.lns',
      incl => $path,
      changes => $changes,
      show_diff => true,
      notify => Service[$::nifi::service::name],
    }
  }
}