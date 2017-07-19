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
        :groups => member_groups
      )
    end
  end

  def self.prefetch(resources)
    repositories = instances
    resources.keys.each do |name|
      if provider = repositories.find { |repository| repository.name == name }
        resources[name].provider = provider
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
      version = found[0]['revision']['version']
      Ent::Nifi::Rest.destroy("tenants/users/#{user_id}", "puppet", version)
    end
  end


  def create
    create_user(@resource[:name], @resource[:groups])
    @property_hash[:ensure] = :present
  end

  def destroy
    delete_user(@resource[:name])
    @property_hash.clear
    @property_hash[:ensure] = :absent
  end

  def refresh
    # ...
  end

  def groups=(value)
    @property_flush[:groups]=value
    @property_hash[:groups] =value
  end

  def insync?(is)
    return false if [:purged, :absent].include?(is)
    should = resource[:groups]
    diff = is - should

    diff.empty?
  end

  # Called once after Puppet creates, destroys or updates a resource
  def flush
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

        current_member_groups = all_groups.select do |group_user|
           group_user['id'] == user_id
        end

        future_member_groups= all_groups.select do |current_group|
          new_groups.include? current_group['component']['identity']
        end


        current_member_groups_ids = current_member_groups.map do |current_group|
          current_group['id']
        end
        future_member_groups_ids = future_member_groups.map do |future_group|
          future_group['id']
        end

        delete_group_ids = current_member_groups_ids- future_member_groups_ids
        add_group_ids = future_member_groups_ids-current_member_groups_ids



        #update each group
        all_groups.map do |select_group|
          group_id =select_group['id']
          version = select_group['revision']['version']
          if add_group_ids.include? group_id
            user_dto_json = to_user_dto(user_json)
            select_group['component']['users'] << user_dto_json
          end
          if delete_group_ids.include? group_id
            #remove user from group
            current_users = select_group['component']['users']
            future_users = current_users.select do |current_user|
              current_user['id'] != user_id
            end

            future_user_dto = future_users.map do |user|
              to_user_dto user
            end
            select_group['component']['users'] = future_user_dto
          end
          Ent::Nifi::Rest.update("tenants/user-groups/#{group_id}", select_group)
        end

      end

      @property_flush = nil
      @property_hash = resource.to_hash
    end
  end


  def to_user_dto(user_json)
    #remove unnecessary element
    user_json['component'].delete('userGroups')
    user_json['component'].delete('accessPolicies')
    return user_json
  end
end