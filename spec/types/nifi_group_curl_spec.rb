require 'spec_helper'

provider_class =Puppet::Type.type(:nifi_group).provider(:curl)

describe  provider_class do
  # Tests will go here
  on_supported_os.each do |os, facts|

    before(:each) do
      puppet_debug_override()
    end
    context "on #{os}" do
      before :each do
        Facter.clear
        facts.each do |k, v|
          Facter.stubs(:fact).with(k).returns Facter.add(k) { setcode { v } }
        end
      end

      context 'create user' do
        let(:resource) {
          Puppet::Type.type(:nifi_group).new({
                                              :ensure=>'present',
                                              :name => 'test',
                                              :auth_cert_path=> '/tmp/auth_cert.pem',
                                              :auth_cert_key_path => '/tmp/auth.key',
                                              :api_url => 'https://datafeed-nf02a.dev.co.entpub.net:8443/nifi-api',
                                              :provider => 'curl'
                                            })
        }
        let(:provider) { #described_class.new(resource)
          resource.provider
        }
        before :each do
          #puts provider.pretty_inspect
          provider.stubs(:curl).with(
            ['-k', '-X', 'GET', '--cert', '/tmp/auth_cert.pem', '--key', '/tmp/auth.key', 'https://datafeed-nf02a.dev.co.entpub.net:8443/nifi-api/tenants/search-results?q=test']
          ).returns('
            {
            "userGroups": [
              {
                "revision": {
              "version": 0
            },
              "id": "65a6839c-015c-1000-ffff-ffffee0e468c",
              "permissions": {
              "canRead": true,
            "canWrite": true
            },
              "component": {
              "id": "65a6839c-015c-1000-ffff-ffffee0e468c",
              "identity": "test"
            }
            }
            ],
              "users": []
            }'
          )

          #provider.stubs(:java).with('-version').returns('9')

        end

        describe 'create group' do
          it 'makes a group' do
            provider.expects(:curl).with(
              ['-k', '-X', 'POST', '--cert', '/tmp/auth_cert.pem', '--key', '/tmp/auth.key', 'https://datafeed-nf02a.dev.co.entpub.net:8443/nifi-api/tenants/user-groups']
            )
            expect(provider.create).to be_truthy
            expect(provider.exists?).to be_truthy
          end
        end
      end


      context 'delete group' do
        let(:resource) {
          Puppet::Type.type(:nifi_group).new({
                                              :ensure=>'present',
                                              :name => 'test2',
                                              :auth_cert_path=> '/tmp/auth_cert.pem',
                                              :auth_cert_key_path => '/tmp/auth.key',
                                              :api_url => 'https://datafeed-nf02a.dev.co.entpub.net:8443/nifi-api',
                                              :provider => 'curl'
                                            })
        }
        let(:provider) { #described_class.new(resource)
          resource.provider
        }
        describe 'delete a group' do
          it 'delete group specified ' do
            provider.expects(:curl).with(
              ['-k', '-X', 'GET', '--cert', '/tmp/auth_cert.pem', '--key', '/tmp/auth.key', 'https://datafeed-nf02a.dev.co.entpub.net:8443/nifi-api/tenants/search-results?q=test2']
            ).returns(
              %q{
                {
                "userGroups": [
                  {
                    "revision": {
                  "version": 0
                },
                  "id": "65a6839c-015c-1000-ffff-ffffee0e468c",
                  "permissions": {
                  "canRead": true,
                "canWrite": true
                },
                  "component": {
                  "id": "65a6839c-015c-1000-ffff-ffffee0e468c",
                  "identity": "test2"
                }
                }
                ],
                  "users": []
                } }
            ).then.returns(
              %q{
                {
                "users": [
                ],
                "userGroups": []
                } }
            ).at_least(1)
            provider.expects(:curl).with(
              ['-k', '-X', 'DELETE', '--cert', '/tmp/auth_cert.pem', '--key', '/tmp/auth.key', 'https://datafeed-nf02a.dev.co.entpub.net:8443/nifi-api/tenants/user-groups/65a6839c-015c-1000-ffff-ffffee0e468c']
            ).once
            expect(provider.destroy).to be_truthy
          end
        end
      end

    end
  end
end