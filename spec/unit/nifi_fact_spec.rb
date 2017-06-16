require 'spec_helper'
require 'lib/facter/nifi.rb'
require 'facter'

# RSpec.configure do |c|
#   c.mock_with :rspec
# end

describe Facter::Util::Fact do
  context 'without nifi installed' do
    before {
      Facter.clear
      Facter.fact(:kernel).stubs(:value).returns('Linux')
      Facter::Util::Loader.any_instance.stubs(:load_all)
      Facter.stubs(:value).with('nifi_conf_dir').returns(nil)
      File.stubs(:exists?).with('/opt/nifi/conf/nifi.properties').returns(false)
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
      Facter.stubs(:value).with('nifi_conf_dir').returns('/opt/nifi/conf')
      File.stubs(:exists?).with('/opt/nifi/conf/nifi.properties').returns(true)
      Facter::Util::Resolution.stubs(:exec).with("cat /opt/nifi/conf/nifi.properties | grep https.port |awk -F= '{print $2}'").returns('8443')
      Facter::Util::Resolution.stubs(:exec).with("cat /opt/nifi/conf/nifi.properties | grep https.host |awk -F= '{print $2}'").returns('nifi.test')
      Nifi::Facts.add_facts
    }
    after {
      Facter.clear
    }

    it {
      expect(Facter.fact(:nifi_https_port).value).to eq('8443')
    }

    it {
      expect(Facter.fact(:nifi_https_host).value).to eq('nifi.test')
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

    context 'without cert/key configured, root process group is nil' do
      before {
        Facter.stubs(:value).with(:nifi_https_port).returns('8443')
        Facter.stubs(:value).with(:nifi_https_host).returns('localhost')
        Facter.stubs(:value).with(:nifi_initial_admin_cert).returns('/tmp/admin.crt')
        Facter.stubs(:value).with(:nifi_initial_admin_key).returns('/tmp/admin.key')
        Facter::Util::Resolution.stubs(:exec).with("curl -k --cert /tmp/admin.crt  --key /tmp/admin.key -X GET  https://localhost:8443/nifi-api/process-groups/root -H 'cache-control: no-cache'").returns(%q{
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
        expect(Facter.fact(:nifi_root_process_group).value).to eq('{:id=>"a193bf0b-015b-1000-e31b-9e0d18709aa2", :name=>"Nifi Flow"}')
      }
    end

  end




  # context 'with cert/key configured, root process group is nil' do
  #   before{
  #     Facter.clear
  #     Facter::Util::Loader.any_instance.stubs(:load_all)
  #     Facter.fact(:kernel).stubs(:value).returns('Linux')
  #     Facter.stubs(:value).with(:nifi_https_port).returns('8443')
  #     Facter.stubs(:value).with(:nifi_https_host).returns('localhost')
  #     Facter.stubs(:value).with(:nifi_initial_admin_cert).returns('/tmp/admin.crt')
  #     Facter.stubs(:value).with(:nifi_initial_admin_key).returns('/tmp/admin.key')
  #   }
  #
  #   it {
  #     expect(Facter.fact(:nifi_root_process_group).value).to eq(nil)
  #   }
  # end

end