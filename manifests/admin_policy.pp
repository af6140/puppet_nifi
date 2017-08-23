class nifi::admin_policy(
  $admin_group = 'nifi-admin'
){

  nifi_group {$admin_group:
    ensure => 'present'
  }
  nifi_permission {"flow:read:group:${admin_group}":
    ensure => 'present'
  }
  nifi_permission {"tenants:read:group:${admin_group}":
    ensure => 'present'
  }
  nifi_permission {"tenants:write:group:${admin_group}":
    ensure => 'present'
  }

  nifi_permission {"policies:read:group:${admin_group}":
    ensure => 'present'
  }
  nifi_permission {"policies:write:group:${admin_group}":
    ensure => 'present'
  }

  nifi_permission {"controller:read:group:${admin_group}":
    ensure => 'present'
  }
  nifi_permission {"controller:write:group:${admin_group}":
    ensure => 'present'
  }

  nifi_permission {"site-to-site:read:group:${admin_group}":
    ensure => 'present'
  }

  nifi_permission {"provenance:read:group:${admin_group}":
    ensure => 'present'
  }
  nifi_permission {"system:read:group:${admin_group}":
    ensure => 'present'
  }
  nifi_permission {"counters:read:group:${admin_group}":
    ensure => 'present'
  }

  if $::nifi_root_process_group {
    $root_pg = parsejson($::nifi_root_process_group)
    if $root_pg {
      $root_pg_id = $root_pg['id']
      nifi_permission { "data/process-groups/${root_pg_id}:read:group:${admin_group}":
        ensure => 'present'
      }
      nifi_permission { "data/process-groups/${root_pg_id}:write:group:${admin_group}":
        ensure => 'present'
      }

      nifi_permission { "process-groups/${root_pg_id}:read:group:${admin_group}":
        ensure => 'present'
      }
      nifi_permission { "process-groups/${root_pg_id}:write:group:${admin_group}":
        ensure => 'present'
      }

    }
  }
}