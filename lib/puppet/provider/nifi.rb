require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'puppet_x', 'ent', 'nifi', 'config.rb'))

class Puppet::Provider::Nifi < Puppet::Provider
  require 'json'
  require 'facter'
  require 'uri'


  initvars

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

  def self.get_resource_id(name, type)
    #url: https://datafeed-nf01a.dev.co.entpub.net:8443/nifi-api/flow/search-results?q=DatafeedScheduler
    #response
    # {
    #   "searchResultsDTO": {
    #   "processorResults": [],
    #   "connectionResults": [],
    #   "processGroupResults": [
    #   {
    #     "id": "a6595b63-015b-1000-7def-867e084e4d65",
    #   "groupId": "a193bf0b-015b-1000-e31b-9e0d18709aa2",
    #   "name": "DataFeedScheduler",
    #   "matches": [
    #   "Name: DataFeedScheduler"
    # ]
    # }
    # ],
    #   "inputPortResults": [],
    #   "outputPortResults": [],
    #   "remoteProcessGroupResults": [],
    #   "funnelResults": []
    # }
    # }
    escaped_name = URI.encode(name)
    request_url="#{api_url}/flow-search-results?q=#{escaped_name}"
    response= curl['-k', '-s', '-X', 'GET', '--cert', self.cert_path, '--key', self.key_path, request_url]

    begin
      response_json = JSON.parse(response)
      results = response_json['searchResultsDTO']["#{type}Results"]
      found = results.filter {|e| e['name']==name}
      if found
        found['id']
      else
        nil
      end
    rescue Exception => e
      puts e.message
    end
    nil
  end

  def get_resource_id(name, type)
    self.class.get_resource_id(name, type)
  end

  def self.config
    Ent::Nifi::Config.configure(self.api_url, self.cert_path, self.key_path)
  end

  def config
    self.class.config
  end
end