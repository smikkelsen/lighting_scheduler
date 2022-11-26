ActiveAdmin.register ZoneSet do
  config.comments = false

  permit_params do
    [:name]
  end
  action_item :create_from_current, only: :index do
    link_to 'Create Set From Current', create_from_current_zone_sets_path, method: :post
  end

  action_item :activate_zone_set, only: :show do
    link_to 'Activate Zone Set', activate_zone_set_path(zone_set), method: :post
  end

  collection_action :create_from_current, method: :post do
    zone_set = ZoneSet.create_from_current('Update Me')
    redirect_to edit_zone_set_path(zone_set), notice: "Zone Set Created, update"
  end

  member_action :activate, method: :post do
    resource.activate
    redirect_back fallback_location: zone_set_path(resource), notice: "Activated '#{resource&.name}' Zone Set"
  end

end
