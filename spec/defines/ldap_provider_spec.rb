require 'spec_helper'

describe 'nifi::ldap_provider' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:title) {'nifi-ldap-provider'}
      let(:facts) do
        facts[:concat_basedir] = '/tmp'
        facts
      end
      let(:pre_condition) {
        "include nifi"
      }
      context "with non-default parameters" do
        let(:params) {
          {
            'provider_properties' => {
              "authentication_strategy" => "START_TLS2"
            }
          }
        }
        it {
          is_expected.to contain_concat__fragment('frag_ldap-provider').with_content(
            /<property name="Authentication Strategy">START_TLS2<\/property>/
          )
        }
      end

      context "without parameter" do
        it {
           is_expected.to have_concat_fragment_count(0)
        }
      end
    end
  end
end