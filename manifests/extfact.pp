define nifi::extfact(
  $key = undef,
  $value = undef,
){

  file_line {"nifi_extfact_$key":
    ensure => present,
    path => "${::nifi::external_fact_dir}/facts.d/nifi.txt",
    line => "${key}=${value}",
    match => "^${key}=",
  }
}
