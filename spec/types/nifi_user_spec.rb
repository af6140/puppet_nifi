require 'spec_helper'

describe Puppet::Type.type(:nifi_user) do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      before :each do
        Facter.clear
        facts.each do |k, v|
          Facter.stubs(:fact).with(k).returns Facter.add(k) { setcode { v } }
        end
      end
      describe 'when validating attributes' do
        [ :name, :auth_cert_path, :auth_cert_key_path ].each do |param|
          it "should have a #{param} parameter" do
            expect(described_class.attrtype(param)).to eq(:param)
          end
        end
        [ :ensure ].each do |prop|
          it "should have a #{prop} property" do
            expect(described_class.attrtype(prop)).to eq(:property)
          end
        end

        describe 'ensure' do
          [ :present, :absent ].each do |value|
            it "should support #{value} as a value to ensure" do
              expect { described_class.new({
                                             :name   => 'test',
                                             :ensure => value,
                                           })}.to_not raise_error
            end
          end
        end

      end

      describe "namevar validation" do
        it "should have :name as its namevar" do
          expect(described_class.key_attributes).to eq([:name])
        end
      end

    end
  end
end