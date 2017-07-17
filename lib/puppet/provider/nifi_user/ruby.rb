require File.expand_path(File.join(File.dirname(__FILE__), '..', 'nifi'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'ent', 'nifi', 'rest.rb'))
Puppet::Type.type(:nifi_user).provide(:ruby, :parent=> Puppet::Provider::Nifi ) do

  mk_resource_methods
  def initialize(value={})
    super(value)
    config
    @property_flush = {}
  end
  def self.instances
    config
    users_raw = Ent::Nifi::Rest.get_users
    if users_raw.nil?
      return []
    end
    users_raw.map do |user_json|
      user_groups = user_json['component']['userGroups']
      member_groups = user_groups.map do |user_group|
        user_group['component']['identity']
      end
      new(:name => user_json['component']['identity'],
        :ensure => :present,
        :gruops => member_groups
      )
    end
  end

  def self.prefetch(resources)
    # resources parameter is an hash of resources managed by Puppet (catalog)
    resource_instances = instances
    resources.keys.each do |name|
      if provider = resource_instances.find{ |r| r.name == name }
        r[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end



  def create_user(username, groups)
    #Example post
    # {
    #   "revision": {
    #   "clientId": "value",
    #   "version": 0,
    #   "lastModifier": "value"
    # },
    #   "id": "value",
    #   "uri": "value",
    #   "position": {
    #   "x": 0.0,
    #   "y": 0.0
    # },
    #   "permissions": {
    #   "canRead": true,
    # "canWrite": true
    # },
    #   "bulletins": [{
    #                   "id": 0,
    #   "groupId": "value",
    #   "sourceId": "value",
    #   "timestamp": "value",
    #   "nodeAddress": "value",
    #   "canRead": true,
    # "bulletin": {…}
    # }],
    #   "component": {
    #   "id": "value",
    #   "parentGroupId": "value",
    #   "position": {…},
    #   "identity": "value",
    #   "userGroups": [{…}],
    #   "accessPolicies": [{…}]
    # }
    # }

    req_json_str = %Q{
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
        "component": {
          "id": null,
          "parentGroupId": null,
          "identity": "#{username}",
          "userGroups": [],
          "accessPolicies": []
        }
      }
    }
    user_json = JSON.parse(req_json_str)
    all_groups = Ent::Nifi::Rest.get_groups
    selected_groups = all_groups.select do |current_group|
      groups.include? current_group['component']['identity']
    end
    user_json['component']['userGroups']= selected_groups
    #puts "request_json :#{req_json}"
    Ent::Nifi::Rest.create("tenants/users", user_json )
  end

  def delete_user(username)
    config
    users = Ent::Nifi::Rest.get_users
    found=users.select do |user|
      user['component']['identity']==username
    end
    if ! found.nil? and ! found[0].nil?
      user_id = found[0]['id']
      Ent::Nifi::Rest.destroy("tenants/users/#{user_id}")
    end
  end


  def create
    puts "Creating user ......"
    create_user(@resource[:name], @resource[:groups])
    @property_hash[:ensure] = :present
  end

  def destroy
    delete_user(@resource[:name])
    @property_hash[:ensure] = :absent
  end

  def refresh
    # ...
  end

  def groups=(value)
    @property_flush[:groups]=value
  end

  # Called once after Puppet creates, destroys or updates a resource
  def flush
    puts "flusing......"
    if @property_flush
      # update resource here
      users_raw = Ent::Nifi::Rest.search_tenant(@resource[:name])['users']
      if users_raw.nil? || users_raw[0].nil?
        #new user create it
        create_user(@resource[:name], @property_flush[:groups])
      else
        #existing user
        user_id = users_raw[0]['id']
        user_json = Ent::Nifi::Rest.get_all("tenants/users/#{user_id}")
        all_groups = Ent::Nifi::Rest.get_groups
        new_groups = @property_flush[:groups]
        selected_groups = all_groups.select do |current_group|
          new_groups.include? current_group['component']['identity']
        end
        user_json['component']['userGroups']= new_groups
        Ent::Nifi::Rest.update("tenants/users/#{user_id}", user_json)
      end

      @property_flush = nil
    end
    @property_hash = resource.to_hash
  end

end