require 'spec_helper'

describe 'nifi' do
  let(:hiera_config) { 'spec/fixtures/hiera/hiera.yaml' }
  hiera = Hiera.new(:config => 'spec/fixtures/hiera/hiera.yaml')

  cluster_members = %w(nifi-as01a.dev nifi-as02a.dev nif-as03a.dev)
  cluster_identities = %w(nifi-as01a.dev nifi-as02a.dev nif-as03a.dev)
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os} without cluster config" do
        let(:facts) do
          facts[:concat_basedir] = '/tmp'
          facts[:fqdn] = 'nifi-as01a.dev'
          facts
        end

        let(:params) {
          {
            :config_cluster => false,
            :cluster_members => %w(nifi-as01a.dev nifi-as02a.dev nif-as03a.dev)
          }
        }


        context "nifi class without any parameters" do
          it { is_expected.to compile.with_all_deps }

          it { is_expected.to contain_class('nifi::params') }
          it { is_expected.to contain_class('nifi::install').that_comes_before('nifi::config') }
          it { is_expected.to contain_class('nifi::config') }
          it { is_expected.to contain_class('nifi::service').that_subscribes_to('nifi::config') }

          it { is_expected.to contain_service('nifi') }
          it { is_expected.to contain_package('nifi') }

          it { is_expected.to contain_ini_setting('nifi_setting_nifi_flow_configuration_file') }

          it { is_expected.to contain_ini_setting('nifi_bootstrap_jvm_minheap').with_setting('java.arg.2').with_value('-Xms512m') }
          it { is_expected.to contain_ini_setting('nifi_bootstrap_jvm_maxheap').with_setting('java.arg.3').with_value('-Xmx512m') }

          it { is_expected.to contain_ini_setting('nifi_setting_nifi_web_http_port').with_setting('nifi.web.http.port')
                                .with_value('8080')
          }

          it { is_expected.to contain_ini_setting('nifi_setting_nifi_web_http_host').with_setting('nifi.web.http.host')
                                .with_value('nifi-as01a.dev')
          }

          it { is_expected.to contain_concat('/opt/nifi/conf/login-identity-providers.xml') }

          it { is_expected.to contain_concat__fragment('id_provider_start') }
          it { is_expected.to contain_concat__fragment('id_provider_end') }

          it { is_expected.to contain_concat('/opt/nifi/conf/state-management.xml') }
          it { is_expected.to contain_concat__fragment('state_provider_start') }
          it { is_expected.to contain_concat__fragment('state_provider_end') }
          it { is_expected.to contain_concat__fragment('frag_local_state_provider') }
          it { is_expected.to contain_concat__fragment('frag_cluster_state_provider') }

          it { is_expected.to contain_nifi__local_state_provider('local_state_provider') }

          it { is_expected.to contain_nifi__file_authorizer('nifi_file_authorizer') }

          it { is_expected.to contain_file('/opt/nifi/flow/custom.properties') }
        end
      end

      context "on #{os} without cluster config, with ldap id provider" do
        let(:facts) do
          facts[:concat_basedir] = '/tmp'
          facts[:fqdn] = 'nifi-as01a.dev'
          facts
        end

        let(:params) {
          {
            :config_cluster => false,
            :ldap_provider_configs => {
              'manager_DN' => 'cn=nifibinding, ou=it, cn=example, cn=com'
            }
          }
        }
        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_service('nifi') }

        it { is_expected.to contain_nifi__ldap_provider('ldap_provider') }
      end

      # #https://github.com/rodjek/rspec-puppet/issues/398
      # #bug failed test
      # context "on #{os} without cluster config, with custom properties" do
      #   let(:facts) do
      #     facts[:concat_basedir] = '/tmp'
      #     facts[:fqdn] = 'nifi-as01a.dev'
      #     facts
      #   end
      #
      #   let(:params) {
      #     {
      #       :config_cluster => false,
      #       :custom_properties => {
      #         'ssh_host' => 'sshost.gov'
      #       }
      #     }
      #   }
      #   it { is_expected.to compile.with_all_deps }
      #   it { is_expected.to contain_service('nifi') }
      #
      # end

      context "on #{os} without cluster config, with ssl config" do
        let(:facts) do
          facts[:concat_basedir] = '/tmp'
          facts[:fqdn] = 'nifi-as01a.dev'
          facts
        end

        let(:params) {
          {
            :config_cluster => false,
            :config_ssl => true,
            :cacert => 'cacert',
            :node_cert => 'node_cert',
            :node_private_key => 'node_key',
            :initial_admin_identity => 'cn=admin',
            :initial_admin_cert => 'admin_cert',
            :initial_admin_key => 'admin_key',
            :keystore_password => 'changeit',
            :key_password => 'secret',
            :client_auth => true,
          }
        }
        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_service('nifi') }

        #it { is_expected.to contain_nifi__ldap_provider('ldap_provider')}

        #testing security setup
        it { is_expected.to contain_nifi__security('nifi_properties_security_setting') }
        it { is_expected.to contain_file('/opt/nifi/conf/certs/ca.pem').with_content(/cacert/) }
        it { is_expected.to contain_ini_setting('nifi_setting_nifi_security_keystorePasswd').with_setting('nifi.security.keystorePasswd')
                              .with_value('changeit')
        }
        it { is_expected.to contain_ini_setting('nifi_setting_nifi_security_keyPasswd').with_setting('nifi.security.keyPasswd')
                              .with_value('secret')
        }
        it { is_expected.to contain_java_ks('nifi_keystore:nifi-as01a.dev') }
        it { is_expected.to contain_java_ks('nifi_truststore:ca') }

        #test authorizer settings
        # it { is_expected.to contain_concat__fragment('frag_authorizer_file-provider')
        #                       .with_content(/<property name="Initial Admin Identity">cn=admin<\/property>/)
        # }

      end


      context "on #{os} with cluster config, implicit ssl config" do
        let(:facts) do
          facts[:concat_basedir] = '/tmp'
          facts
        end

        let(:params) {
          {
            :config_ssl  => true,
            :config_cluster => true,
            :cacert => 'cacert',
            :node_cert => 'node_cert',
            :node_private_key => 'node_key',
            :initial_admin_identity => 'cn=admin',
            :initial_admin_cert => 'admin_cert',
            :initial_admin_key => 'admin_key',
            :keystore_password => 'changeit',
            :key_password => 'secret',
            :client_auth => true,
            :cluster_members => cluster_members,
            :cluster_identities => cluster_identities,
          }
        }


        context "nifi class without any parameters" do
          it { is_expected.to compile.with_all_deps }

          it { is_expected.to contain_class('nifi::params') }
          it { is_expected.to contain_class('nifi::install').that_comes_before('nifi::config') }
          it { is_expected.to contain_class('nifi::config') }
          it { is_expected.to contain_class('nifi::service').that_subscribes_to('nifi::config') }

          it { is_expected.to contain_service('nifi') }
          it { is_expected.to contain_package('nifi') }

          it { is_expected.to contain_ini_setting('nifi_setting_nifi_flow_configuration_file') }

          it { is_expected.to contain_ini_setting('nifi_setting_nifi_state_management_embedded_zookeeper_start')
                                .with_setting('nifi.state.management.embedded.zookeeper.start')
                                .with_value('true')
          }
          it { is_expected.to contain_nifi__embedded_zookeeper('nifi_zookeeper_config') }
          it { is_expected.to contain_ini_setting('zookeeper_member_1') }

          it { is_expected.to contain_ini_setting('nifi_setting_nifi_cluster_is_node').with_setting('nifi.cluster.is.node').with_value('true') }

          it { is_expected.to contain_file('/opt/nifi/conf/state/zookeeper/myid') }

          it { is_expected.to contain_nifi__cluster_state_provider('cluster_state_provider') }

          it { is_expected.to contain_concat__fragment('frag_authorizer_file-provider')
                                .with_content(/<property name="Node Identity 1">nifi-as01a\.dev<\/property>/)
          }
        end
      end

    end
  end

  context 'unsupported operating system' do
    describe 'nifi class without any parameters on Solaris/Nexenta' do
      let(:facts) do
        {
          :osfamily => 'Solaris',
          :operatingsystem => 'Nexenta',
        }
      end

      it { expect { is_expected.to contain_package('nifi') }.to raise_error(Puppet::Error, /Nexenta not supported/) }
    end
  end
end
