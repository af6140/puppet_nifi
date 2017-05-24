define nifi::config_properties (
  $path = "${nifi::nifi_conf_dir}/nifi.properties",
  $properties = {}
){
  #notify {"$properties": }
  assert_type(Hash[String,Scalar], $properties)
  if ! empty($properties) {
    $changes = $properties.map |String $key, Scalar $value| {
      "set ${key} '${value}'"
    }
    notify{"changes ${title}":
        message => $changes
    }
    augeas {"update-nifi-properties-${title}":
      lens => 'Properties.lns',
      incl => $path,
      changes => $changes,
      show_diff => true,
    }
  }
}