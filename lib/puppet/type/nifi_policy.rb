Puppet::Type.newtype(:nifi_policy) do
  @doc = %q{Create a new user in nifi
    Example:
      nifi_policy {
         ensure => present,
      }
  }
  ensurable

  newparam(:name, :namevar => true) do
    desc "The name of the user"

    validate do | value |
      if ! /([a-zA-Z0-9\-_]+):(read|write)/.match(value)
        raise ArgumentError,
              "Policy name must match action:resource format like read:provenance "
      end
    end
  end

end