Puppet::Type.newtype(:nifi_group) do
  @doc = %q{Create a new user in nifi
    Example:
      nifi_user {
         ensure => present,
      }
  }
  ensurable

  newparam(:name, :namevar => true) do
    desc "The name of the group"

    validate do | value |
      if ! /[a-zA-Z0-9\-_]+/.match(value)
        raise ArgumentError,
              "User name must match /[a-zA-Z0-9\\-_]+/"
      end
    end
  end

  newparam(:require_cluster) do
    defaultto true
    newvalues(true, false)
  end

end