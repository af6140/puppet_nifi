require File.expand_path(File.join(File.dirname(__FILE__), '..', 'nifi'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'ent', 'nifi', 'rest.rb'))

require 'uri'
require 'json'

Puppet::Type.type(:nifi_permission).provide(:ruby, :parent=> Puppet::Provider::Nifi ) do
  mk_resource_methods
  #confine :feature => :restclient
  def exists?
    name  = @resource['name']
    name_specs= name.split(':')
    permission_resource = name_specs[0]
    permission_action = name_specs[1]
    permission_entity = name_specs[2]
    permission_entity_name = name_specs[3]
    config
    existing_policy = get_policy(permission_action, permission_resource)
    if ! existing_policy.nil?
      if permission_entity == 'user'
        users= existing_policy['component']['users'].map do  | entry |
          entry['component']['identity']
        end
        return users.include?(permission_entity_name)
      end
      if permission_entity=='group'
        groups= existing_policy['component']['userGroups'].map do  | entry |
          entry['component']['identity']
        end
        return groups.include?(permission_entity_name)
      end
      return false
    else
      return false
    end
  end

  def get_policy(action, resource)
    encode_resource = URI.escape(resource)
    config
    begin
      resource_path="policies/#{action}/#{encode_resource}"
      search_json = Ent::Nifi::Rest.get_all(resource_path)
    rescue Exception=>e
      puts e.message
      search_json = nil
    end
    search_json
  end

  def create
    name_spec  = @resource['name']
    name_specs= name_spec.split(':')
    policy_resource = name_specs[0]
    policy_action = name_specs[1]
    permission_entity = name_specs[2]
    permission_entity_name = name_specs[3]

    config
    Ent::Nifi::Rest.node_ok(@resource[:require_cluster])
    if permission_entity == 'user'
      users = Ent::Nifi::Rest.get_users
      target = users.select { |item|  permission_entity_name == item['component']['identity']}
    end
    if permission_entity == 'group'
      groups = Ent::Nifi::Rest.get_groups
      target = groups.select { |item|  permission_entity_name == item['component']['identity']}
    end

    tenant_id = target[0].nil? ? nil : target[0]['component']['id']

    if tenant_id.nil?
      return false
    end

    existing_policy = get_policy(policy_action, policy_resource)
    policy_id = existing_policy['id']

    if existing_policy.nil?
      tenant_entry = {
        "revision" => {
          "version" => 0
        },
        "id" => tenant_id,
        "permissions" => {
          "canRead" => true,
          "canWrite" => true
        },
        "component" => {
          "id" => tenant_id,
          "identity" => permission_entity_name
        }
      }
      tenant_entry_json = tenant_entry.to_json
      if permission_entity=='user'
        request_json = %Q{
          {
            "revision": {
              "version": 0
            },
            "id": null,
            "uri": null,
            "position": {
              "x": 0.0,
              "y": 0.0
            },
            "permissions": {
              "canRead": true,
              "canWrite": true
            },
            "generated": "false",
            "component": {
              "id": "",
              "parentGroupId": "",
              "resource": "#{policy_resource}",
              "action": "#{policy_action}",
              "users": [#{tenant_entry_json}],
              "userGroups": []
            }
          }
      }
      else
        request_json = %Q{
          {
            "revision": {
              "version": 0
            },
            "id": null,
            "uri": null,
            "position": {
              "x": 0.0,
              "y": 0.0
            },
            "permissions": {
              "canRead": true,
              "canWrite": true
            },
            "generated": "false",
            "component": {
              "id": "",
              "parentGroupId": "",
              "resource": "#{policy_resource}",
              "action": "#{policy_action}",
              "users": [],
              "userGroups": [#{tenant_entry_json}]
            }
          }
      }
      end
      Ent::Nifi::Rest.create('policies', JSON.parse(request_json))
    else
      #policy exists now update permssion
      tenant_entry = {
        "revision" => {
          "version" => 0
        },
        "id" => tenant_id,
        "permissions" => {
          "canRead" => true,
          "canWrite" => true
        },
        "component" => {
          "id" => tenant_id,
          "identity" => permission_entity_name
        }
      }
      if permission_entity=='user'
        existing_policy['component']['users'] << tenant_entry
        version = existing_policy['revision']['version']
      end
      if permission_entity=='group'
        version = existing_policy['revision']['version']
        existing_policy['component']['userGroups'] << tenant_entry
      end
      Ent::Nifi::Rest.update("/policies/#{policy_id}", existing_policy)
    end
    @property_hash[:ensure] = :present
    exists? ? true : false
  end

  def destroy
    name = @resource['name']
    name_specs= name.split(':')
    policy_resource = name_specs[0]
    policy_action = name_specs[1]
    delete_permission(policy_resource, policy_action)
    @property_hash.clear
    exists? ? (return false) :(return true)
  end


  def delete_permission(resource, action)
    policy_json = get_policy(action, resource)
    policy_id = policy_json['id']
    policy_version = policy_json['revision']['version']
    config
    Ent::Nifi::Rest.node_ok(@resource[:require_cluster])
    Ent::Nifi::Rest.destroy("policies/#{policy_id}", 'puppet', policy_version)
  end

end