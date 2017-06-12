class Puppet::Provider::Nifi < Puppet::Provider
  require 'json'

  #check curl command exists
  confine :true => begin
    system("curl -V")
  end

  initvars

  commands :curl => 'curl'
  #mk_resource_methods


  #default nothing returned
  def self.instances
    []
  end

end