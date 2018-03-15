require 'spec_helper'
require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'beaker/puppet_install_helper'

hosts.each do |host|
 if host['roles'].include?('centos') and host['roles'].include?('agent')
  ENV["PUPPET_INSTALL_TYPE"] = "foss"
  ENV["PUPPET_INSTALL_VERSION"] = "3.8.7-1.el7"
  run_puppet_install_helper unless ENV['BEAKER_provision'] == 'no'
  case fact_on(host, "osfamily")
  when 'RedHat'
      case fact_on(host,'os')['release']['major']
      when '7'
        install_package(host, 'deltarpm')
        #on host, 'yum -y update'
        %w(bzip2 tar wget initscripts git rsync).each do |pkg_to_install|
          install_package(host, pkg_to_install)
        end
      when '6'
        %w(bzip2 tar wget git rsync).each do |pkg_to_install|
          install_package(host, pkg_to_install)
        end
      else
        puts fact_on(host,'os')
      end
  end
 end
end

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  user_home = File.expand_path("~")

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    #puppet_module_install(:source => proj_root, :module_name => 'nifi', :target_module_path=>'/etc/puppetlabs/code/environments/production/modules')
    puppet_module_install(:source => proj_root, :module_name => 'nifi', :target_module_path=>'/etc/puppet/modules')
    master = ''
    begin
      master = only_host_with_role(hosts, 'master')
      master_fqdn = "#{master}"
    rescue => error
      puts "No puppet master defined."
    end

    hosts.each do |host|
      #setup ssh key for git operation to stash
      if File.exist?("#{user_home}/.ssh/id_rsa")
        on host, "umask 077 && mkdir -p /root/.ssh "
        scp_to host, "#{user_home}/.ssh/id_rsa", "/root/.ssh/id_rsa_git"
        on host, 'echo "StrictHostKeyChecking no">> /root/.ssh/config'
        on host, 'echo "Host stash.entertainment.com " >> /root/.ssh/config'
        on host, 'echo "   IdentityFile ~/.ssh/id_rsa_git">> /root/.ssh/config'
        on host, "cat /root/.ssh/config"
      end

      on host, 'rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm'

      #use internal ca cert
      scp_to host, "#{proj_root}/spec/fixtures/ent_ca.crt", "/etc/pki/ca-trust/source/anchors"
      on host, "update-ca-trust extract"

      #configure agent to use future parser and strict variables
      if host['roles'].include?('agent')
        agent = host
        agent_name = agent.to_s.downcase
        agent_fqdn ="#{agent_name}"

        config = {
            'main' => {
                'server' => master_fqdn,
                'certname' => agent_fqdn,
                'parser' => 'future',
                'strict_variables' => 'true',
            }
        }

        #work around issue host[:hieradatadir] not set when BEAKER_provision=no
        host[:hieradatadir] = '/etc/puppet/hieradata' unless host[:hieradatadir]
        on host, "if [ ! -d /etc/puppet/hieradata ]; then mkdir /etc/puppet/hieradata; fi"

        hierarchy = ['common']
        write_hiera_config_on(host, hierarchy)

        hierarchy.each do |f|
           copy_hiera_data_to(host, "#{proj_root}/spec/fixtures/hiera/hieradata/#{f}.yaml") #?? buggy
        end

        on host, puppet('module', 'install', 'puppetlabs-stdlib --version 4.6.0'), { :acceptable_exit_codes => [0,1] }
        on host, puppet('module', 'install', 'puppetlabs-inifile'), { :acceptable_exit_codes => [0,1] }
        on host, puppet('module', 'install', 'puppetlabs-concat --version 1.2.5'), { :acceptable_exit_codes => [0,1] }
        on host, puppet('module', 'install', 'puppetlabs-java_ks --version 1.4.1'), { :acceptable_exit_codes => [0,1] }

      end

    end
  end
end

