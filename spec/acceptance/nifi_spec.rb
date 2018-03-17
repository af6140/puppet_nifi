require 'spec_helper_acceptance'

describe 'nifi class' do
  context 'default parameters' do
    # Using puppet_apply as a helper
    it 'should work idempotently with no errors' do
      pp = <<-EOS
      class { 'nifi':
        config_ssl => false
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true, :strict_variables=> true, :future_parser=>true)
      apply_manifest(pp, :catch_changes  => true, :strict_variables=> true, :future_parser=>true)
    end

  end
end
