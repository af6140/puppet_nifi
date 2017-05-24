define nifi::idmapping_dn (
  $pattern = undef,
  $value = undef,
  $index = undef,
  $ensure = 'present'
) {

  assert_type(String[1], $pattern)
  assert_type(String[1], $value)
  assert_type(Integer[0, 99], $index)

  if($index==0){
    $real_index =''
  }else {
    #1 is 2
    $real_index=$index+1
  }
  $id_mapping_props= {
    "nifi.security.identity.mapping.pattern.dn${real_index}" => $pattern,
    "nifi.security.identity.mapping.value.dn${real_index}" => $value
  }

  nifi::config_properties {'nifi_idmapping_configs':
    properties => $id_mapping_props
  }
}