source "https://rubygems.org"

group :test do
  gem "rake"
  gem "puppet", ENV['PUPPET_GEM_VERSION'] || '~> 3.8.0'
  gem "puppet-syntax"
  gem "rspec"
  gem "rspec-puppet"
  gem "rspec-puppet-facts"
  gem "puppetlabs_spec_helper"
  gem "metadata-json-lint"
  gem "json", "1.8.1"
  gem "rspec_junit_formatter"

  gem "puppet-lint-absolute_classname-check"
  gem "puppet-lint-leading_zero-check"
  gem "puppet-lint-trailing_comma-check"
  gem "puppet-lint-version_comparison-check"
  gem "puppet-lint-classes_and_types_beginning_with_digits-check"
  gem "puppet-lint-unquoted_string-check"
end

group :development do
  gem "puppet-blacksmith"
  gem "modulesync"
end

group :acceptance_test do
  gem "beaker"
  gem "beaker-rspec"
  gem "beaker-puppet_install_helper"
end

group :build do
  gem "rest-client", "1.7.2"
  gem "entertainment-gem-pulp", :require => false, :source => "https://nexus.prod.co.entpub.net/nexus/content/repositories/entertainment_gems"
  gem "mgit_util", :require => false, :source => "https://nexus.prod.co.entpub.net/nexus/content/repositories/entertainment_gems"
  gem "bamboo_util", :require => false, :source => "https://nexus.prod.co.entpub.net/nexus/content/repositories/entertainment_gems"
  gem "puppet_build_util", :require => false, :source => "https://nexus.prod.co.entpub.net/nexus/content/repositories/entertainment_gems"
end
