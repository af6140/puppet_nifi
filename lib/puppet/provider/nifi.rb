class Puppet::Provider::Nifi < Puppet::Provider
  require 'json'
  require 'facter'

  #check curl command exists
  confine :true => begin
    system("curl -V")
  end

  initvars

  commands :curl => 'curl'
  commands :cat => 'cat'
  #mk_resource_methods


  #default nothing returned
  def self.instances
    []
  end

  def self.api_url
    https_host = Facter.value(:nifi_https_host)
    https_port = Facter.value(:nifi_https_port)
    "https://#{https_host}:#{https_port}/nifi-api"
  end

  def api_url
    self.class.api_url
  end

  def self.cert_path
    Facter.value(:nifi_initial_admin_cert_path)
  end

  def cert_path
    self.class.cert_path
  end

  def self.key_path
    Facter.value(:nifi_initial_admin_key_path)
  end

  def key_path
    self.class.key_path
  end
end