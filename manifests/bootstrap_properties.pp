define nifi::bootstrap_properties (
  $path = "${nifi::nifi_conf_dir}/bootstrap.conf",
  $properties = {}
){
  assert_type(Hash[String,Scalar], $properties)

  if ! empty($properties) {
    $changes = $properties.map |String $key, Scalar $value| {
      "set ${key} '${value}'"
    }

    augeas {"update-nifi-bootstrap-${title}":
      lens => 'Properties.lns',
      incl => $path,
      changes => $changes,
      show_diff => true,
    }
  }
}