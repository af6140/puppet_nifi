require 'spec_helper'

provider_class =Puppet::Type.type(:nifi_user).provider(:curl)

describe  provider_class do
  # Tests will go here

  let(:nifi_https_host) {
    'nifi-test'
  }
  let(:nifi_https_port) {
    '8443'
  }
  let(:nifi_initial_admin_cert_path) {
    '/tmp/auth_cert.pem'
  }
  let(:nifi_initial_admin_key_path) {
    '/tmp/auth.key'
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

      context 'create user' do
        let(:resource) {
          Puppet::Type.type(:nifi_user).new({
                                              :ensure=>'present',
                                              :name => 'test',
                                              :provider => 'curl'
                                            })
        }
        let(:provider) { #described_class.new(resource)
          resource.provider
        }
        before :each do
          #puts provider.pretty_inspect
          provider.stubs(:curl).with(
            ['-k', '-X', 'GET', '--cert', nifi_initial_admin_cert_path, '--key', nifi_initial_admin_key_path, "https://#{nifi_https_host}:#{nifi_https_port}/nifi-api/tenants/search-results?q=test"]
          ).returns('
            {
            "users": [
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
              "userGroups": []
            }'
          )

          #provider.stubs(:java).with('-version').returns('9')

        end

        describe 'create user' do
          it 'makes a user' do
            provider.expects(:curl).with(
              ['-k', '-X', 'POST', '--cert', nifi_initial_admin_cert_path, '--key', nifi_initial_admin_key_path, "https://#{nifi_https_host}:#{nifi_https_port}/nifi-api/tenants/users"]
            )
            expect(provider.create).to be_truthy
            expect(provider.exists?).to be_truthy
          end
        end
      end


      context 'delete user' do
        let(:resource) {
          Puppet::Type.type(:nifi_user).new({
                                              :ensure=>'present',
                                              :name => 'test2',
                                              :provider => 'curl'
                                            })
        }
        let(:provider) { #described_class.new(resource)
          resource.provider
        }
        describe 'delete an  user' do
          it 'delete user specified ' do
            provider.expects(:curl).with(
              ['-k', '-X', 'GET', '--cert', nifi_initial_admin_cert_path, '--key', nifi_initial_admin_key_path, "https://#{nifi_https_host}:#{nifi_https_port}/nifi-api/tenants/search-results?q=test2"]
            ).returns(
              %q{
                {
                "users": [
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
                  "userGroups": []
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
              ['-k', '-X', 'DELETE', '--cert', nifi_initial_admin_cert_path, '--key', nifi_initial_admin_key_path, "https://#{nifi_https_host}:#{nifi_https_port}/nifi-api/tenants/users/65a6839c-015c-1000-ffff-ffffee0e468c"]
            ).once
            expect(provider.destroy).to be_truthy
          end
        end
      end

    end
  end
end