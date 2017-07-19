require 'facter'
require 'json'

require "net/https"
require "uri"



module Nifi
  module Http
    def self.get_http(uri, cert_path, key_path)
      begin
        uri = URI.parse(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        cert_raw = File.read(cert_path)
        #puts cert_raw
        http.cert = OpenSSL::X509::Certificate.new(cert_raw)
        key_raw = File.read(key_path)
        http.key = OpenSSL::PKey::RSA.new(key_raw)
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        return http
      rescue Exception => e
        puts e.message
        puts e.backtrace.inspect
        return nil
      end
    end
  end

  module Facts
    def self.add_facts
      Facter.add(:nifi_https_port) do
        confine :kernel => "Linux"
        setcode do
          conf_dir = Facter.value('nifi_conf_dir')
          conf_file =File.join(conf_dir, 'nifi.properties')
          port = Nifi::Configuration.https_port(conf_file)
          port.nil? ? '' : port
        end
      end

      Facter.add(:nifi_https_host) do
        confine :kernel => "Linux"
        setcode do
          conf_dir = Facter.value('nifi_conf_dir')
          conf_file =File.join(conf_dir, 'nifi.properties')
          host = Nifi::Configuration.https_host(conf_file)
          host.nil? ? '' : host
        end
      end

      Facter.add(:nifi_root_process_group) do
        confine :kernel => "Linux"
        setcode do
          rg = Nifi::Flow.rootProcessGroup
          rg.nil? ? '' : rg
        end
      end
      #
      Facter.add(:nifi_process_groups) do
        confine :kernel => "Linux"
        setcode do
          Nifi::Flow.processGroups
        end
      end

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
      if cert_path.nil? or cert_key.nil? or https_host.nil? or https_port.nil?
        return nil
      end

      if !File.exists?(cert_path) or !File.exists?(cert_key)
        return nil
      end

      cmd = %Q{curl -k --cert #{cert_path}  --key #{cert_key} -X GET  https://#{https_host}:#{https_port}/nifi-api/process-groups/root -H 'cache-control: no-cache'}
      result = Facter::Util::Resolution.exec(cmd)

      all_pg=[]
      if ! result.nil?
        root_json = JSON.parse(result)
        root_id = root_json['id']
        data = {
          'id' => root_id,
          'name' => root_json['component']['name']
        }
        all_pg.push(data)
        others = Nifi::Flow.navigatProcessGroups(root_id)
        all_pg.concat(others)
      end
      return all_pg.to_s
    end

    def self.navigatProcessGroups(pg_id)
      cert_path = Facter.value(:nifi_initial_admin_cert)
      cert_key = Facter.value(:nifi_initial_admin_key)
      https_host = Facter.value(:nifi_https_host)
      https_port = Facter.value(:nifi_https_port)
      cmd = %Q{curl -k --cert #{cert_path}  --key #{cert_key} -X GET  https://#{https_host}:#{https_port}/nifi-api/process-groups/#{pg_id}/process-groups -H 'cache-control: no-cache'}
      result = Facter::Util::Resolution.exec(cmd)
      all_pg=[]
      if ! result.nil?
        result_json=JSON.parse(result)
        pg_json = result_json['processGroups']
        select_pg_json = pg_json.select  {|e| e['id'] != pg_id } # get rid of itself
        pg_data = select_pg_json.map do |pg|
          data= {
            'id' => pg['id'],
            'name' => pg['component']['name'],
            'parent' => pg['component']['parentGroupId']
          }
        end
        all_pg.concat(pg_data)
        pg_data.each do | next_pg |
          next_pg_id = next_pg['id']
          next_level_data = navigatProcessGroups(next_pg_id)
          all_pg.concat(next_level_data)
        end
      end
      return all_pg
    end
    def self.rootProcessGroup
      cert_path = Facter.value(:nifi_initial_admin_cert)
      cert_key = Facter.value(:nifi_initial_admin_key)
      https_host = Facter.value(:nifi_https_host)
      https_port = Facter.value(:nifi_https_port)

      if cert_path.nil? or cert_key.nil? or https_host.nil? or https_port.nil?
        return nil
      end

      cmd = %Q{curl -k --cert #{cert_path}  --key #{cert_key} -X GET  https://#{https_host}:#{https_port}/nifi-api/process-groups/root -H 'cache-control: no-cache'}

      # url = "https://#{https_host}:#{https_port}/nifi-api/process-groups/root"
      # http = Nifi::Http.get_http(url, cert_path, cert_key)
      # request = Net::HTTP::Get.new(url)
      # request.add_field('cache-control', 'no-cache')
      # response = nil
      # begin
      #   response = http.request(request)
      #   result = response.body
      #   puts response.status
      # rescue Exception =>e
      #   puts e.message
      #   puts e.backtrace.inspect
      # end
      # if response.status == '200'
      #   puts "parsing results"
      #   root_json = JSON.parse(result)
      #   puts "parsed: #{root_json}"
      #   data = {
      #     :id => root_json['id'],
      #     :name => root_json['component']['name']
      #   }
      #   puts "data:#{data}"
      #   return data.to_s
      # else
      #   puts "result is nil"
      #   return nil
      # end

      result = Facter::Util::Resolution.exec(cmd)
      if result
        root_json = JSON.parse(result)
        data = {
          'id' => root_json['id'],
          'name' => root_json['component']['name']
        }
        return data.to_s
      end

    end
  end
end

Nifi::Facts.add_facts
