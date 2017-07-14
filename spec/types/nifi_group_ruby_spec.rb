require 'spec_helper'
require 'rest-client'
provider_class =Puppet::Type.type(:nifi_group).provider(:ruby)

describe  provider_class do
  # Tests will go here
  let(:nifi_https_host) {
    'nifi-test'
  }
  let(:nifi_https_port) {
    '8443'
  }
  let(:nifi_initial_admin_cert_path) {
    File.expand_path(File.join(File.dirname(__FILE__), '..', 'fixtures', 'ssl', 'cert.pem'))
  }
  let(:nifi_initial_admin_key_path) {
    File.expand_path(File.join(File.dirname(__FILE__), '..', 'fixtures', 'ssl', 'key.pem'))
  }
  on_supported_os.each do |os, facts|

    before(:each) do
      puppet_debug_override()
    end
    context "on #{os}" do
      before :each do
        Facter.clear
        facts[:nifi_https_host]=nifi_https_host
        facts[:nifi_https_port]=nifi_https_port
        facts[:nifi_initial_admin_cert_path]=nifi_initial_admin_cert_path
        facts[:nifi_initial_admin_key_path]=nifi_initial_admin_key_path
        facts.each do |k, v|
          Facter.stubs(:fact).with(k).returns Facter.add(k) { setcode { v } }
        end
      end

      context 'create new group' do
        let(:resource) {
          Puppet::Type.type(:nifi_group).new({
                                              :ensure=>'present',
                                              :name => 'test',
                                              :provider => 'ruby'
                                            })
        }
        let(:provider) { #described_class.new(resource)
          resource.provider
        }
        before :each do
          stub_request(:post, "https://nifi-test:8443/nifi-api/tenants/user-groups").
            to_return(:status => 200, :body => "", :headers => {})
        end

        it 'makes a group' do
          expect(provider.create).to be_truthy
          expect(provider.exists?).to be_truthy
        end

      end
    end
  end
end