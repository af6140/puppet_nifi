require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'puppet_x', 'ent', 'nifi', 'config.rb'))

class Puppet::Provider::Nifi < Puppet::Provider
  require 'json'
  require 'facter'
  require 'uri'


  initvars

  confine :feature => :restclient

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

  def self.config
    Ent::Nifi::Config.configure(self.api_url, self.cert_path, self.key_path)
  end

  def config
    self.class.config
  end
end