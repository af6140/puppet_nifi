require 'spec_helper'
require 'lib/facter/nifi.rb'
require 'facter'
require "net/https"
require "uri"
#require 'webmock/rspec'

#WebMock.disable_net_connect!(:allow_localhost => true)

# RSpec.configure do |c|
#   c.mock_with :rspec
# end

describe Facter::Util::Fact do

  let(:nifi_test_host) {
    'nifi-test'
  }
  let(:nifi_test_port) {
    '8443'
  }
  let(:nifi_conf_dir) {
    '/opt/nifi/conf'
  }
  let(:nifi_properties_path) {
    "#{nifi_conf_dir}/nifi.properties"
  }
  let(:cert_path) {
    File.expand_path(File.join(File.dirname(File.expand_path(__FILE__)), '..', 'fixtures', 'ssl', 'cert.pem'))
  }
  let(:key_path) {
    File.expand_path(File.join(File.dirname(File.expand_path(__FILE__)), '..', 'fixtures', 'ssl', 'key.pem'))
  }

  context 'without nifi installed' do
    before {
      Facter.clear
      Facter.fact(:kernel).stubs(:value).returns('Linux')
      Facter::Util::Loader.any_instance.stubs(:load_all)
      Facter.stubs(:value).with('nifi_conf_dir').returns(nil)
      File.stubs(:exists?).with(nifi_properties_path).returns(false)
      Nifi::Facts.add_facts
    }

    after {
      Facter.clear
    }

    it {
      expect(Facter.fact(:nifi_https_port).value).to eq(nil)
    }

    it {
      expect(Facter.fact(:nifi_https_host).value).to eq(nil)
    }
  end

  context 'with nifi installed' do
    before {
      Facter.clear
      Facter::Util::Loader.any_instance.stubs(:load_all)
      Facter.fact(:kernel).stubs(:value).returns('Linux')
      Facter.stubs(:value).with('nifi_conf_dir').returns(nifi_conf_dir)
      File.stubs(:exists?).with(nifi_properties_path).returns(true)
      File.stubs(:exists?).with(cert_path).returns(true)
      File.stubs(:exists?).with(key_path).returns(true)
      Facter::Util::Resolution.stubs(:exec).with("cat #{nifi_properties_path} | grep https.port |awk -F= '{print $2}'").returns(nifi_test_port)
      Facter::Util::Resolution.stubs(:exec).with("cat #{nifi_properties_path} | grep https.host |awk -F= '{print $2}'").returns(nifi_test_host)
      Nifi::Facts.add_facts
    }
    after {
      Facter.clear
    }

    it {
      expect(Facter.fact(:nifi_https_port).value).to eq(nifi_test_port)
    }

    it {
      expect(Facter.fact(:nifi_https_host).value).to eq(nifi_test_host)
    }

    context 'without cert/key configured, root process group is nil' do
      before{
        Facter.stubs(:value).with(:nifi_https_port).returns(nil)
        Facter.stubs(:value).with(:nifi_https_host).returns(nil)
        Facter.stubs(:value).with(:nifi_initial_admin_cert).returns(nil)
        Facter.stubs(:value).with(:nifi_initial_admin_key).returns(nil)
      }
      it {
        expect(Facter.fact(:nifi_root_process_group).value).to eq(nil)
      }
    end

    context 'with cert/key configured, root process group is nil' do
      before {
        Facter.stubs(:value).with(:nifi_https_port).returns(nifi_test_port)
        Facter.stubs(:value).with(:nifi_https_host).returns(nifi_test_host)
        #Facter.stubs(:value).with(:nifi_initial_admin_cert).returns('/tmp/admin.crt')
        #Facter.stubs(:value).with(:nifi_initial_admin_key).returns('/tmp/admin.key')
        Facter.stubs(:value).with(:nifi_initial_admin_cert).returns(cert_path)
        Facter.stubs(:value).with(:nifi_initial_admin_key).returns(key_path)
        Facter::Util::Resolution.stubs(:exec).with("curl -k --cert #{cert_path}  --key #{key_path} -X GET  https://#{nifi_test_host}:#{nifi_test_port}/nifi-api/process-groups/root -H 'cache-control: no-cache'").returns(%q{
              {
                "revision": {
                    "version": 0
                },
                "id": "a193bf0b-015b-1000-e31b-9e0d18709aa2",
                "component": {
                  "name": "Nifi Flow"
                }
              }
         }
        )
      }
      it {
        expect(Facter.fact(:nifi_root_process_group).value).to eq('{"id"=>"a193bf0b-015b-1000-e31b-9e0d18709aa2", "name"=>"Nifi Flow"}')
      }
    end

    context 'with cert/key configured, all process groups' do
      before{
        #Facter.fact(:kernel).stubs(:value).returns('Linux')
        Facter.stubs(:value).with(:nifi_https_port).returns(nifi_test_port)
        Facter.stubs(:value).with(:nifi_https_host).returns(nifi_test_host)
        Facter.stubs(:value).with(:nifi_initial_admin_cert).returns(cert_path)
        Facter.stubs(:value).with(:nifi_initial_admin_key).returns(key_path)
        Facter::Util::Resolution.stubs(:exec).with("curl -k --cert #{cert_path}  --key #{key_path} -X GET  https://#{nifi_test_host}:#{nifi_test_port}/nifi-api/process-groups/root -H 'cache-control: no-cache'").returns(%q{
              {
                "revision": {
                    "version": 0
                },
                "id": "a193bf0b-015b-1000-e31b-9e0d18709aa2",
                "component": {
                  "name": "Nifi Flow"
                }
              }
         }
        )
        Facter::Util::Resolution.stubs(:exec).with("curl -k --cert #{cert_path}  --key #{key_path} -X GET  https://#{nifi_test_host}:#{nifi_test_port}/nifi-api/process-groups/a193bf0b-015b-1000-e31b-9e0d18709aa2/process-groups -H 'cache-control: no-cache'").returns(%q{
          {
            "processGroups": [
              {
                "revision": {
                    "version": 0
                },
                "id": "a193bf0b-015b-1000-e31b-9e0d18709aa2",
                "component": {
                  "name": "Nifi Flow"
                }
              },
              {
                "revision": {
                    "version": 0
                },
                "id": "a19d963d-015b-1000-a6ae-27c95e00d054",
                "component": {
                  "parentGroupId": "a193bf0b-015b-1000-e31b-9e0d18709aa2",
                  "name": "test group 1"
                }
              }
            ]
          }

        })
        Facter::Util::Resolution.stubs(:exec).with("curl -k --cert #{cert_path}  --key #{key_path} -X GET  https://#{nifi_test_host}:#{nifi_test_port}/nifi-api/process-groups/a19d963d-015b-1000-a6ae-27c95e00d054/process-groups -H 'cache-control: no-cache'").returns(%q{
          { "processGroups": [] }
        })
      } # end before

      it {
        fact_value=Facter.fact(:nifi_process_groups).value
        puts "Got fact nifi_process_groups value: #{fact_value}"
        expect(fact_value).to match(/test group 1/)
      }
    end

    context 'without cert/key configured, all process groups' do
      before{
        Facter.fact(:kernel).stubs(:value).returns('Linux')
        Facter.stubs(:value).with(:nifi_https_port).returns(nil)
        Facter.stubs(:value).with(:nifi_https_host).returns(nifi_test_host)
        Facter.stubs(:value).with(:nifi_initial_admin_cert).returns(cert_path)
        Facter.stubs(:value).with(:nifi_initial_admin_key).returns(key_path)
        Facter::Util::Resolution.stubs(:exec).with("curl -k --cert #{cert_path}  --key #{key_path} -X GET  https://#{nifi_test_host}:#{nifi_test_port}/nifi-api/process-groups/root -H 'cache-control: no-cache'").returns(%q{
              {
                "revision": {
                    "version": 0
                },
                "id": "a193bf0b-015b-1000-e31b-9e0d18709aa2",
                "component": {
                  "name": "Nifi Flow"
                }
              }
         }
        )
        Facter::Util::Resolution.stubs(:exec).with("curl -k --cert #{cert_path}  --key #{key_path} -X GET  https://#{nifi_test_host}:#{nifi_test_port}/nifi-api/process-groups/a193bf0b-015b-1000-e31b-9e0d18709aa2/process-groups -H 'cache-control: no-cache'").returns(%q{
          {
            "processGroups": [
              {
                "revision": {
                    "version": 0
                },
                "id": "a193bf0b-015b-1000-e31b-9e0d18709aa2",
                "component": {
                  "name": "Nifi Flow"
                }
              },
              {
                "revision": {
                    "version": 0
                },
                "id": "a19d963d-015b-1000-a6ae-27c95e00d054",
                "component": {
                  "parentGroupId": "a193bf0b-015b-1000-e31b-9e0d18709aa2",
                  "name": "test group 1"
                }
              }
            ]
          }

        })
        Facter::Util::Resolution.stubs(:exec).with("curl -k --cert #{cert_path}  --key #{key_path} -X GET  https://#{nifi_test_host}:#{nifi_test_port}/nifi-api/process-groups/a19d963d-015b-1000-a6ae-27c95e00d054/process-groups -H 'cache-control: no-cache'").returns(%q{
          { "processGroups": [] }
        })
      } # end before

      it {
        fact_value=Facter.fact(:nifi_process_groups).value
        expect(fact_value).to eq(nil)
      }
    end

  end

end