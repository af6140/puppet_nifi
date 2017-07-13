require 'spec_helper'
require 'rest-client'

provider_class =Puppet::Type.type(:nifi_permission).provider(:ruby)

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

      context 'create group permission' do
        let(:group) {
          'nifi-admin'
        }
        let(:target_resource){
          'flow'
        }
        let(:resource) {
          Puppet::Type.type(:nifi_permission).new({
                                              :ensure=>'present',
                                              :name => 'read:flow:group:nifi-admin',
                                              :provider => 'ruby'
                                            })
        }
        let(:provider) { #described_class.new(resource)
          resource.provider
        }

        let(:default_policy_flow) {
          %Q{
            {
              "revision": {
                  "version": 0
              },
              "id": "ba5b2211-23b7-3002-ae59-c7ede56a5ab8",
              "uri": "https://#{nifi_https_host}:#{nifi_https_port}/nifi-api/policies/ba5b2211-23b7-3002-ae59-c7ede56a5ab8",
              "permissions": {
                  "canRead": true,
                  "canWrite": true
              },
              "generated": "16:48:35 EDT",
              "component": {
                  "id": "ba5b2211-23b7-3002-ae59-c7ede56a5ab8",
                  "resource": "/#{target_resource}",
                  "action": "read",
                  "users": [
                      {
                          "revision": {
                              "version": 0
                          },
                          "id": "e4394252-1e50-37f7-9ba2-a02907ea7f52",
                          "permissions": {
                              "canRead": true,
                              "canWrite": true
                          },
                          "component": {
                              "id": "e4394252-1e50-37f7-9ba2-a02907ea7f52",
                              "identity": "nifi-admin-prod"
                          }
                      }
                  ],
                  "userGroups": [
                  ]
              }
            }
          }
        }

        let(:updated_policy_flow) {
          %Q{
            {
              "revision": {
                  "version": 0
              },
              "id": "ba5b2211-23b7-3002-ae59-c7ede56a5ab8",
              "uri": "https://#{nifi_https_host}:#{nifi_https_port}/nifi-api/policies/ba5b2211-23b7-3002-ae59-c7ede56a5ab8",
              "permissions": {
                  "canRead": true,
                  "canWrite": true
              },
              "generated": "16:48:35 EDT",
              "component": {
                  "id": "ba5b2211-23b7-3002-ae59-c7ede56a5ab8",
                  "resource": "/#{target_resource}",
                  "action": "read",
                  "users": [
                      {
                          "revision": {
                              "version": 0
                          },
                          "id": "e4394252-1e50-37f7-9ba2-a02907ea7f52",
                          "permissions": {
                              "canRead": true,
                              "canWrite": true
                          },
                          "component": {
                              "id": "e4394252-1e50-37f7-9ba2-a02907ea7f52",
                              "identity": "nifi-admin-prod"
                          }
                      }
                  ],
                  "userGroups": [
                      {
                          "revision": {
                              "version": 0
                          },
                          "id": "a1b47e12-015c-1000-ffff-ffff95c53fee",
                          "permissions": {
                              "canRead": true,
                              "canWrite": true
                          },
                          "component": {
                              "id": "a1b47e12-015c-1000-ffff-ffff95c53fee",
                              "identity": "#{group}"
                          }
                      }
                  ]
              }
            }
          }
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
          stub_request(:get, "https://#{nifi_https_host}:#{nifi_https_port}/nifi-api/tenants/user-groups").
            with(:headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => existing_group, :headers => {})

          stub_request(:get, "https://#{nifi_https_host}:#{nifi_https_port}/nifi-api/policies/read/flow").
            with(:headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
            to_return(:status => 200, :body => default_policy_flow, :headers => {}).times(1).then.
            to_return(:status => 200, :body => updated_policy_flow, :headers => {})

          stub_request(:post, "https://#{nifi_https_host}:#{nifi_https_port}/nifi-api/policies").to_return(:status => 203, :body => "test create success", :headers => {})

          stub_request(:put, "https://#{nifi_https_host}:#{nifi_https_port}/nifi-api/policies/ba5b2211-23b7-3002-ae59-c7ede56a5ab8").
            to_return(:status => 200, :body => "", :headers => {})
        end

        describe 'create permission success' do
          it 'create a permssion' do
            expect(provider.create).to be_truthy
          end
        end

        describe 'create existing permission success' do
          it 'create permission idempotently' do
            expect(provider.create).to be_truthy
          end
        end
      end

    end
  end
end