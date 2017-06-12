Puppet::Type.type(:nifi_policy).provide(:curl) do
  require 'json'

  #check curl command exists
  confine :true => begin
    system("curl -V")
  end

  initvars

  commands :curl => 'curl'
  #commands :java  => 'java'
  mk_resource_methods


  def exists?
    name_spec  = @resource['name']
    name_specs= name_spec.split(':')
    policy_resource = name_specs[0]
    policy_action = name_specs[1]
    existing_policy = get_policy(policy_resource, policy_action)
    ! existing_policy.nil?
  end


  def get_policy(resource, action)
    search_command = ['-k', '-X', 'GET', '--cert', @resource[:auth_cert_path], '--key', @resource[:auth_cert_key_path] ,  "#{@resource[:api_url]}/policies/#{action}/#{resource}"]
    search_response = curl(search_command)
    if(search_response.nil?)
      return nil
    else
      policy_json= JSON.parse(search_response)
      return policy_json
    end
  end

  def delete_policy(resrouce, action)
    search_command = ['-k', '-X', 'GET', '--cert', @resource[:auth_cert_path], '--key', @resource[:auth_cert_key_path] ,  "#{@resource[:api_url]}/policies/#{action}/#{resource}"]
    search_response = curl(search_command)
    if(! search_response.nil?)
      policy_json = JSON.parse(search_response)
      id = policy_json['id']
      delete_command = ['-k', '-X', 'DELETE', '--cert', @resource[:auth_cert_path], '--key', @resource[:auth_cert_key_path] ,  "#{@resource[:api_url]}/policies/#{id}"]
      delete_response = curl(delete_command)
      if(delete_response)
        puts("Delete policy response: #{delete_response}")
      end
    end
  end

  def create
    name_spec  = @resource['name']
    name_specs= name_spec.split(':')
    policy_resource = name_specs[0]
    policy_action = name_specs[1]

    request_json = %Q{
        {
          "revision": {
            "version": 0,
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
            "userGroups": []
          }
        }
    }
    create_command = ['-k', '-X', 'POST', '--cert', @resource[:auth_cert_path], '--key', @resource[:auth_cert_key_path] , '-d', request_json, "#{@resource[:api_url]}/policies"]
    create_response = curl(create_command)
    @property_hash[:ensure] = :present
    exists? ? (return true) : (return false)
  end

  def destroy
    name_spec  = @resource['name']
    name_specs= name_spec.split(':')
    policy_resource = name_specs[0]
    policy_action = name_specs[1]
    delete_policy(policy_resource, policy_action)
    @property_hash.clear
    still_there = exists?
    still_there ? (return false) :(return true)
  end
end