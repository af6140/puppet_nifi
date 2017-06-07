require 'hiera'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'
include RspecPuppetFacts


fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))


#enable hiera lookup that used in puppet module itself
RSpec.configure do |c|
  c.hiera_config = "#{fixture_path}/hiera/hiera.yaml"
end


def puppet_debug_override
   #if ENV['SPEC_PUPPET_DEBUG']
     Puppet::Util::Log.level = :debug
     Puppet::Util::Log.newdestination(:console)
   #end
end