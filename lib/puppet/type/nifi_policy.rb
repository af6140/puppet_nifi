Puppet::Type.newtype(:nifi_policy) do
  @doc = %q{Create a new user in nifi
    Example:
      nifi_policy {
         ensure => present,
      }
  }
  ensurable

  @nifi_resource_type =[
    'controller', 'controller-services', 'counters','funnels', 'flow', 'input-ports', 'labels', 'output-ports', 'policies', 'processors',
      'processors', 'process-groups', 'provenance', 'data', 'proxy', 'remote-process-groups', 'reporting-tasks', 'resources',
      'site-to-site', 'data-transfer', 'system', 'restricted-components', 'templates', 'tenants'
  ]

  @nifi_singleton_resource_type =[
    'controller', 'flow'
  ]
  newparam(:name, :namevar => true) do
    desc "The name of the user"

    validate do | value |
      if ! /([a-zA-Z0-9\-\/_]+):([a-zA-Z0-9\s+\-\_]+):(read|write)/.match(value)
        raise ArgumentError,
              "Policy name must match resource;identity(name):action like /provenance::read "
      end

      #parse the target spec
      #   from java code , these are the resources
      #   Controller("/controller"),
      #   ControllerService("/controller-services"),
      #   Counters("/counters"),
      #   Funnel("/funnels"),
      #   Flow("/flow"),
      #   InputPort("/input-ports"),
      #   Label("/labels"),
      #   OutputPort("/output-ports"),
      #   Policy("/policies"),
      #   Processor("/processors"),
      #   ProcessGroup("/process-groups"),
      #   Provenance("/provenance"),
      #   Data("/data"),
      #   Proxy("/proxy"),
      #   RemoteProcessGroup("/remote-process-groups"),
      #   ReportingTask("/reporting-tasks"),
      #   Resource("/resources"),
      #   SiteToSite("/site-to-site"),
      #   DataTransfer("/data-transfer"),
      #   System("/system"),
      #   RestrictedComponents("/restricted-components"),
      #   Template("/templates"),
      #   Tenant("/tenants");

      name_specs= @resource['name'].split(':')
      if name_specs.length < 3
        raise ArgumentError,
              "#{resource['name']} must be resource:name:(read|write) "
      end
    end
  end

end