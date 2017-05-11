require 'spec_helper'

describe 'nifi::ldap_provider' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:title) {'nifi-ldap-provider'}
      let(:facts) do
        facts[:concat_basedir] = '/tmp'
        facts
      end
      context "with parameters" do
        let(:params) {
          {
            'provider_properties' => {
              "authentication_strategy" => "START_TLS"
            }
          }
        }
        it {
          is_expected.to contain_concat__fragment('frag_ldap-provider').with_content(
            /<property name="Authentication Strategy">START_TLS<\/property>/
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