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

  newparam(:auth_cert_path) do
    desc "The cert path for api authentciation"
  end

  newparam(:auth_cert_key_path) do
    desc "The private key path for api authentciation"
  end

  newparam(:api_url) do
    desc "The url to make api all"
    validate do |value|
      if ! /^https.*/.match(value)
        raise ArgumentError,
              "api_url must use https"
      end
    end
  end

end