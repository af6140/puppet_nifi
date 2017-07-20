class nifi::cluster_policy(
  $cluster_members = $::nifi::cluster_members
){
  #create cluster node permissions
  nifi_group {'cluster_nodes':
    ensure => 'present'
  }
  nifi_permission {"controller:read:group:cluster_nodes":
    ensure => 'present'
  }
  nifi_permission {"proxy:read:group:cluster_nodes":
    ensure => 'present'
  }
  nifi_permission {"site-to-site:read:group:cluster_nodes":
    ensure => 'present'
  }
  nifi_permission {"provenance:read:group:cluster_nodes":
    ensure => 'present'
  }
  $root_pg = parsejson($::nifi_root_process_group)
  notify{"${root_pg}": }
  if $root_pg {
    $root_pg_id = $root_pg['id']
    notify {"${root_pg_id}": }
    nifi_permission { "data/process-groups/${root_pg_id}:read:group:cluster_nodes":
      ensure => 'present'
    }
    nifi_permission { "data/process-groups/${root_pg_id}:write:group:cluster_nodes":
      ensure => 'present'
    }
    nifi_permission { "process-groups/${root_pg_id}:read:group:cluster_nodes":
      ensure => 'present'
    }
    nifi_permission { "process-groups/${root_pg_id}:write:group:cluster_nodes":
      ensure => 'present'
    }

    if $cluster_members {
      each($cluster_members)  |$member_node| {

        notify {"${member_node}": }
        nifi_user {$member_node:
          ensure => 'present',
          groups => 'cluster_nodes'
        }
      }
    }
  } else {

  }
}