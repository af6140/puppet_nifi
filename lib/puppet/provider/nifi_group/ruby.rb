require File.expand_path(File.join(File.dirname(__FILE__), '..', 'nifi'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'ent', 'nifi', 'rest.rb'))
Puppet::Type.type(:nifi_group).provide(:ruby, :parent=> Puppet::Provider::Nifi ) do

  mk_resource_methods

  def initialize(value={})
    super(value)
    config
    @property_flush = {}
  end

  def self.instances
    search_json = Ent::Nifi::Rest.get_all("tenants/user-groups")
    if search_json.nil?
      return []
    end
    groups_raw = search_json['userGroups']
    groups_raw.map do |group_json|
      new(:name => group_json['component']['identity'],
          :ensure => :present
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



  def create_group
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
    groupname = @resource[:name]
    req_json = %Q{
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
          "identity": "#{groupname}",
          "userGroups": [],
          "users": [],
          "accessPolicies": []
        }
      }
    }
    Ent::Nifi::Rest.create("tenants/user-groups", JSON.parse(req_json))
  end

  def create
    create_group
    @property_hash[:ensure] = :present
    exists? ? (return true) : (return false)
  end

  def destroy

  end

  def refresh
    # ...
  end

  # Called once after Puppet creates, destroys or updates a resource
  def flush
    if @property_flush
      # update resource here
      @property_flush = nil
    end
    @property_hash = resource.to_hash
  end

end