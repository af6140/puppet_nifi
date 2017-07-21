require 'pathname'
Puppet::Type.newtype(:nifi_permission) do
  @doc = %q{Create a new user in nifi
    Example:
      nifi_user {'test':
         ensure => present,
      }
  }
  ensurable

  newparam(:name, :namevar => true) do
    desc "The name of the user"
    validate do | value |
      #spec
      #resource:[read|write]:[group:user]:group/username
      if ! /([a-zA-Z0-9\-\/_]+):(read|write):(group|user):([a-zA-Z0-9\-_]+)/.match(value)
        raise ArgumentError,
              ' name must match /([a-zA-Z0-9\-_]+):(read|write):(group|user):([a-zA-Z0-9\-_]+)/'
      end
    end
  end

  newparam(:require_cluster) do
    defaultto true
    newvalues(true, false)
  end

end