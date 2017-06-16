require 'facter'
require 'json'

module Nifi
  module Facts
    def self.add_facts
      Facter.add(:nifi_https_port) do
        confine :kernel => "Linux"
        setcode do
          conf_dir = Facter.value('nifi_conf_dir')
          conf_file =File.join(conf_dir, 'nifi.properties')
          Nifi::Configuration.https_port(conf_file)
        end
      end

      Facter.add(:nifi_https_host) do
        confine :kernel => "Linux"
        setcode do
          conf_dir = Facter.value('nifi_conf_dir')
          conf_file =File.join(conf_dir, 'nifi.properties')
          Nifi::Configuration.https_host(conf_file)
        end
      end

      Facter.add(:nifi_root_process_group) do
        confine :kernel => "Linux"
        setcode do
          Nifi::Flow.rootProcessGroup
        end
      end
      #
      # Facter.add(:nifi_process_groups) do
      #   confine :kernel => "Linux"
      #   setcode do
      #     Nifi::Facts::Flow.processGroups
      #   end
      # end

      return nil
    end

  end

  module Configuration
    def self.https_port(conf_file)
      if File.exists?(conf_file)
        Facter::Util::Resolution.exec("cat #{conf_file} | grep https.port |awk -F= '{print $2}'")
      else
        puts "not finding properties file"
        nil
      end
    end

    def self.https_host(conf_file)
      if File.exists?(conf_file)
        Facter::Util::Resolution.exec("cat #{conf_file} | grep https.host |awk -F= '{print $2}'")
      else
        nil
      end
    end
  end

  module Flow
    def self.processGroups
      cert_path = Facter.value(:nifi_initial_admin_cert)
      cert_key = Facter.value(:nifi_initial_admin_key)
      https_host = Facter.value(:nifi_https_host)
      https_port = Facter.value(:nifi_https_port)
      if (cert_path.nil? or cert_key.nil? or https_host.nil? or https_port.nil? )
        return nil
      end

      if !File.exists?(cert_path) or !File.exists?(cert_key)
        return nil
      end

      cmd = %Q{ curl -k --cert #{cert_path}  --key #{cert_key} -X GET  https://#{https_host}:#{https_port}/nifi-api/process-groups/root -H 'cache-control: no-cache' }
      result = Facter::Core::Execution.exec(cmd)
      all_pg=[]
      if ! result.nil?
        root_json = JSON.parse(result)
        root_id = root_json['id']
        data = {
          :id => root_id,
          :name => root_json['component']['name']
        }
        all_pg.push(data)
        others = navigatProcessGroups(root_id)
        all_pg.concat(others)
      end
      return all_pg.to_s
    end

    def self.navigatProcessGroups(pg_id)
      cmd = %Q{ curl -k --cert #{cert_path}  --key #{cert_key} -X GET  https://#{https_host}:#{https_port}/nifi-api/process-groups/#{pg_id}/process-groups -H 'cache-control: no-cache' }
      result = Facter::Core::Execution.exec(cmd)
      all_pg=[]
      if ! result.nil?
        result_json=JSON.parse(result)
        pg_json = result_json['processGroups']
        pg_data = pg_json.map do |pg|
          data= {
            :id => pg['id'],
            :name => pg['component']['name'],
            :parent => pg['component']['parentGroupId']
          }
        end
        all_pg.concat(pg_data)
        pg_data.each do | next_pg |
          next_level_data = navigatProcessGroups(next_pg['id'])
          all_pg.concat(next_level_data)
        end
      end
      return all_pg
    end
    def self.rootProcessGroup
      puts("get process group")
      cert_path = Facter.value(:nifi_initial_admin_cert)
      cert_key = Facter.value(:nifi_initial_admin_key)
      https_host = Facter.value(:nifi_https_host)
      https_port = Facter.value(:nifi_https_port)

      if cert_path.nil? or cert_key.nil? or https_host.nil? or https_port.nil?
        return nil
      end

      cmd = %Q{curl -k --cert #{cert_path}  --key #{cert_key} -X GET  https://#{https_host}:#{https_port}/nifi-api/process-groups/root -H 'cache-control: no-cache'}
      result = Facter::Util::Resolution.exec(cmd)
      puts "result: #{result}"
      if ! result.nil?
        puts "parsing results"
        root_json = JSON.parse(result)
        puts "parsed: #{root_json}"
        data = {
          :id => root_json['id'],
          :name => root_json['component']['name']
        }
        puts "data:#{data}"
        return data.to_s
      else
        puts "result is nil"
        return nil
      end
    end
  end
end

Nifi::Facts.add_facts
