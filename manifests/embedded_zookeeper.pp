define nifi::embedded_zookeeper (
  $members =[]
){

  assert_type(Array, $members)

 if ! empty($members) {
   $members.each |$index, $member|{
     $real_index=$index+1
     ini_setting {"zookeeper_member_${real_index}":
       ensure => present,
       path   => '/opt/nifi/conf/zookeeper.properties',
       section_prefix => '',
       section_suffix => '',
       setting => "zookeeper.${real_index}",
       value => "${member}:2888:3888"
     }
     #set zookeeper myid
     # echo $id > .state/zookeeper/myid
     if $::fqdn == $member {
     file {'/opt/nifi/conf/state/':
       ensure => 'directory',
       owner => 'nifi',
       group => 'nifi',
       mode => '0755'
     } ->
     file {'/opt/nifi/conf/state/zookeeper':
       ensure => 'directory',
       owner => 'nifi',
       group => 'nifi',
       mode => '0755'
     } ->
     file {'/opt/nifi/conf/state/zookeeper/myid':
         ensure => 'present',
         content => "$real_index",
         owner => 'nifi',
         group => 'nifi',
         mode => '0644'
       }
     }
   }
 }else {
   ini_setting {"zookeeper_member_1":
     ensure => present,
     path   => '/opt/nifi/conf/zookeeper.properties',
     section_prefix => '',
     section_suffix => '',
     setting => "zookeeper.1",
     value => "%",
   }
 }
}