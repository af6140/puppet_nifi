require 'rubygems'
require 'bundler/setup'

require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet/version'
require 'puppet/vendor/semantic/lib/semantic' unless Puppet.version.to_f < 3.6
require 'puppet-lint/tasks/puppet-lint'
require 'puppet-syntax/tasks/puppet-syntax'
require 'metadata-json-lint/rake_task'
require 'mgit_util/rake_tasks'
require 'bamboo_util/rake_tasks'
require 'puppet_build_util/rake_tasks'

# These gems aren't always present, for instance
# on Travis with --without development
begin
  require 'puppet_blacksmith/rake_tasks'
rescue LoadError
end
begin
  if File.exist?(File.join(Dir.home, '.pulpforge.yml'))
    puts "Loading pulp gem"
    require 'entertainment-gem-pulp/rake_tasks'
  end
rescue LoadError
end


exclude_paths = [
  "bundle/**/*",
  "pkg/**/*",
  "vendor/**/*",
  "spec/**/*",
]

# Coverage from puppetlabs-spec-helper requires rcov which
# doesn't work in anything since 1.8.7
#Rake::Task[:coverage].clear

Rake::Task[:lint].clear

PuppetLint.configuration.fail_on_warnings = true
PuppetLint.configuration.send('disable_80chars')
PuppetLint.configuration.send('disable_class_inherits_from_params_class')
PuppetLint.configuration.send('disable_class_parameter_defaults')
PuppetLint.configuration.send('disable_arrow_alignment')
PuppetLint.configuration.send('relative')
PuppetLint.configuration.ignore_paths = exclude_paths


desc "Run acceptance tests"
RSpec::Core::RakeTask.new(:acceptance) do |t|
  t.pattern = 'spec/acceptance'
end

desc "Run syntax, lint, and spec tests."
task :test => [
  :metadata_lint,
  :syntax,
  :lint,
  :spec,
]

SPEC_SUITES = [
   { :id => :default, :title => 'default acceptance test', :pattern => %w(spec/acceptance/class_spec.rb) },
]

namespace :acceptance do
    SPEC_SUITES.each do |suite|
      desc "Run all specs in #{suite[:title]} spec suite"
      RSpec::Core::RakeTask.new(suite[:id]) do |t|
        ENV["BEAKER_set"] = suite[:set] || 'default'
        t.rspec_opts = ['--options', "\".rspec\""]
        t.pattern= suite[:pattern]
      end
    end
end
