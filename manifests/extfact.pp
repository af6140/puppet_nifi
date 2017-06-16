define nifi::extfact(
  $key = undef,
  $value = undef,
){

  file_line {"nifi_extfact_$key":
    ensure => present,
    path => '/etc/fact/facts.d/nifi.txt',
    line => "${key}=${value}",
    match => "^${key}=",
  }
}