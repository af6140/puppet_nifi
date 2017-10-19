define nifi::custom_properties (
  $properties=$::nifi::custom_properties,
  $custom_file = $::nifi::custom_properties_file
) {

  if $properties {
    assert_type(Hash[String,String], $properties)
    $nifi_custom_properties = $properties
    $real_content = template('nifi/custom.properties.erb')
  }else {
    $real_content = ''
  }

  file { $custom_file:
    ensure => 'present',
    owner => 'nifi',
    group => 'nifi',
    mode => '0600',
    content => $real_content,
    notify => Service[$::nifi::service::name],
  }
}