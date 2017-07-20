class nifi::cluster_policy{
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
  if $root_pg {
    $root_pg_id = $root_pg['id']
    nifi_permission {"data/process-groups/${root_pg_id}:read:group:cluster_nodes":
      ensure => 'present'
    }
    nifi_permission {"data/process-groups/${root_pg_id}:write:group:cluster_nodes":
      ensure => 'present'
    }

    if $::nifi::config_cluster and ! empty($::nifi::cluster_members) {
      each($::nifi::cluster_members) |$cluster_node| {
        nifi_user {$cluster_node:
          groups => 'cluster_nodes'
        }
    }
  }
}