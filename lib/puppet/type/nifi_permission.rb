require 'pathname'
Puppet::Type.newtype(:nifi_permission) do
  @doc = %q{Create a new user in nifi
    Example:
      nifi_user {
         ensure => present,
      }
  }
  ensurable

  newparam(:name, :namevar => true) do
    desc "The name of the user"

    validate do | value |
      #spec
      #resource:[read|write]:[group:user]:group/username
      if ! /(read|write):([a-zA-Z0-9\-\/_]+):(group|user):([a-zA-Z0-9\-_]+)/.match(value)
        raise ArgumentError,
              ' name must match /(read|write):([a-zA-Z0-9\-_]+):(group|user):([a-zA-Z0-9\-_]+)/'
      end
    end
  end
end