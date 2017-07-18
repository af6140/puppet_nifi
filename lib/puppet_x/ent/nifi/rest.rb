require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'ent', 'nifi', 'config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'ent', 'nifi', 'exception.rb'))
require 'json'
require 'uri'
require 'rest-client'
module Ent
  module Nifi
    class Rest
      def self.request
        nifi_config = Ent::Nifi::Config.config
          nifi = RestClient::Resource.new(
            nifi_config[:url],
            :ssl_client_cert => nifi_config[:cert],
            :ssl_client_key => nifi_config[:key],
            :verify_ssl => OpenSSL::SSL::VERIFY_NONE
          )
        yield nifi
      end

      def self.get_all(resource_name)
        request { |nifi|
          begin
            response = nifi[resource_name].get(:accept => :json)
          rescue => e
            Ent::Nifi::ExceptionHandler.process(e) { |msg|
              raise "Could not request #{resource_name} from #{nifi.url}: #{msg}"
            }
          end

          begin
            JSON.parse(response)
          rescue => e
            raise "Could not parse the JSON response from Nexus (url: #{nifi.url}, resource: #{resource_name}): #{e} (response: #{response})"
          end
        }
      end

      def self.create(resource_name, data)
        request { |nifi|
          begin
            nifi[resource_name].post JSON.generate(data), :accept => :json, :content_type => :json
          rescue => e
            Ent::Nifi::ExceptionHandler.process(e) { |msg|
              raise "Could not create #{resource_name} at #{nifi.url}: #{msg}"
            }
          end
        }
      end

      def self.update(resource_name, data)
        request { |nifi|
          begin
            nifi[resource_name].put JSON.generate(data), :accept => :json, :content_type => :json
          rescue => e
            Ent::Nifi::ExceptionHandler.process(e) { |msg|
              raise "Could not update #{resource_name} at #{nifi.url}: #{msg}"
            }
          end
        }
      end

      def self.destroy(resource_name)
        request { |nifi|
          begin
            nifi[resource_name].delete params: {version: '9999', clientId: 'puppet'}, :accept => :json
          rescue RestClient::ResourceNotFound
            # resource already deleted, nothing to do
          rescue => e
            Ent::Nifi::ExceptionHandler.process(e) { |msg|
              raise "Could not delete #{resource_name} at #{nifi.url}: #{msg}"
            }
          end
        }
      end

      def self.get_users
        result = get_all("tenants/users")
        result.nil? ? [] : result['users']
      end

      def self.get_groups
        result = get_all("tenants/user-groups")
        result.nil? ? [] : result['userGroups']
      end

      def self.search_tenant(tenant_name)
        request { |nifi|
          begin
            response = nifi["tenants/search-results"].get(:accept => :json, :params => {q:URI.escape(tenant_name)})
          rescue => e
            Ent::Nifi::ExceptionHandler.process(e) { |msg|
              raise "Could not request #{resource_name} from #{nifi.url}: #{msg}"
            }
          end

          begin
            JSON.parse(response)
          rescue => e
            raise "Could not parse the JSON response from Nexus (url: #{nifi.url}, resource: #{resource_name}): #{e} (response: #{response})"
          end
        }
      end

    end
  end
end