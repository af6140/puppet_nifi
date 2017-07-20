require 'spec_helper'
require 'json'

describe 'nifi::cluster_policy' do
  let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }
  hiera = Hiera.new(:config => 'spec/fixtures/hiera/hiera.yaml')
  id_mappings = hiera.lookup('nifi_profiles::id_mapping', nil, 'common')
  cluster_members = %w(nifi-as01a.dev nifi-as02a.dev nif-as03a.dev)
  cluster_identities = %w(nifi-as01a.dev nifi-as02a.dev nif-as03a.dev)
  let(:root_pg) {
    '{"id":"a193bf0b-015b-1000-e31b-9e0d18709aa2", "name":"NiFi Flow"}'
  }
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os} without cluster config" do
        let(:facts) do
          facts[:concat_basedir] = '/tmp'
          facts[:fqdn] = 'nifi-as01a.dev'
          facts[:nifi_root_process_group] = root_pg
          facts
        end

        let(:params) {
          {
            :cluster_members => cluster_members
          }
        }

        before {
          Facter.clear
        }
        context "nifi::cluster_policy class without any parameters" do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_nifi_group('cluster_nodes') }

          it { is_expected.to contain_nifi_permission('provenance:read:group:cluster_nodes') }

          it { is_expected.to contain_nifi_permission('process-groups/a193bf0b-015b-1000-e31b-9e0d18709aa2:read:group:cluster_nodes') }
        end

        after {
          Facter.clear
        }
      end
    end
  end
end
