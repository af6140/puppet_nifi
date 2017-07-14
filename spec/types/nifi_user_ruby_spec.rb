require 'spec_helper'
require 'rest-client'

provider_class =Puppet::Type.type(:nifi_user).provider(:ruby)

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

      context 'create user with empty group' do
        let(:resource) {
          Puppet::Type.type(:nifi_user).new({
                                              :ensure=>'present',
                                              :name => 'test',
                                              :provider => 'ruby'
                                            })
        }
        let(:group) {
          'nifi-admin'
        }
        let(:provider) { #described_class.new(resource)
          resource.provider
        }
        let(:existing_group ) {
          %Q{
              {
                  "userGroups": [
                      {
                          "revision": {
                              "version": 0
                          },
                          "id": "a1b47e12-015c-1000-ffff-ffff95c53fee",
                          "uri": "https://#{nifi_https_host}:#{nifi_https_port}/nifi-api/tenants/user-groups/a1b47e12-015c-1000-ffff-ffff95c53fee",
                          "permissions": {
                              "canRead": true,
                              "canWrite": true
                          },
                          "component": {
                              "id": "a1b47e12-015c-1000-ffff-ffff95c53fee",
                              "identity": "#{group}",
                              "users": [ ]
                          }
                      }
                  ]
              }
          }
        }
        before :each do
          #puts provider.pretty_inspect
          #provider.stubs(:java).with('-version').returns('9')
          stub_request(:get, "https://#{nifi_https_host}:#{nifi_https_port}/nifi-api/tenants/user-groups").
            with(:headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => existing_group, :headers => {})

          stub_request(:post, "https://nifi-test:8443/nifi-api/tenants/users").
            to_return(:status => 200)
        end


        it 'makes a user' do
          expect(provider.create).to be_truthy
          expect(provider.exists?).to be_truthy
        end

      end


      context 'create user with groups' do
        let(:resource) {
          Puppet::Type.type(:nifi_user).new({
                                              :ensure=>'present',
                                              :name => 'test',
                                              :groups => 'nifi-admin',
                                              :provider => 'ruby'
                                            })
        }
        let(:group) {
          'nifi-admin'
        }
        let(:provider) { #described_class.new(resource)
          resource.provider
        }
        let(:existing_group ) {
          %Q{
              {
                  "userGroups": [
                      {
                          "revision": {
                              "version": 0
                          },
                          "id": "a1b47e12-015c-1000-ffff-ffff95c53fee",
                          "uri": "https://#{nifi_https_host}:#{nifi_https_port}/nifi-api/tenants/user-groups/a1b47e12-015c-1000-ffff-ffff95c53fee",
                          "permissions": {
                              "canRead": true,
                              "canWrite": true
                          },
                          "component": {
                              "id": "a1b47e12-015c-1000-ffff-ffff95c53fee",
                              "identity": "#{group}",
                              "users": [ ]
                          }
                      }
                  ]
              }
          }
        }
        before :each do
          #puts provider.pretty_inspect
          #provider.stubs(:java).with('-version').returns('9')
          stub_request(:get, "https://#{nifi_https_host}:#{nifi_https_port}/nifi-api/tenants/user-groups").
            with(:headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => existing_group, :headers => {})

          stub_request(:post, "https://nifi-test:8443/nifi-api/tenants/users").
            to_return(:status => 200)
        end


        it 'makes a user' do
          expect(provider.create).to be_truthy
          expect(provider.exists?).to be_truthy
        end

      end

    end
  end
end