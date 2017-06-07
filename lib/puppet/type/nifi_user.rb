Puppet::Type.newtype :nifi_user do
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
        if /[a-z0-9\-_]+/.match(value)
          super
        else
          raise ArgumentError,
                "User name must mbe /[a-zA-Z0-9\\-_]+/"
        end
    end
  end

end