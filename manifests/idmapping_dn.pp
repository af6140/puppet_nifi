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
  ini_setting{"idmapping_dn_pattern_${real_index}":
    ensure => $ensure,
    path   => "${::nifi::nifi_conf_dir}/nifi.properties",
    section_prefix => '',
    section_suffix => '',
    setting => "nifi.security.identity.mapping.pattern.dn${real_index}",
    value => $pattern
  }

  ini_setting{"idmapping_dn_value_${real_index}":
    ensure => $ensure,
    path   => "${::nifi::nifi_conf_dir}/nifi.properties",
    section_prefix => '',
    section_suffix => '',
    setting => "nifi.security.identity.mapping.value.dn${real_index}",
    value => $value
  }
}