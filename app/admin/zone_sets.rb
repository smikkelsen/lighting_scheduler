ActiveAdmin.register ZoneSet do
  config.comments = false

  permit_params do
    [:name]
  end
  action_item :create_from_current, only: :index do
    link_to 'Create Set From Current', create_from_current_zone_sets_path, method: :post
  end

  collection_action :create_from_current, method: :post do
    zone_set = ZoneSet.create_from_current('Update Me')
    redirect_to edit_zone_set_path(zone_set), notice: "Zone Set Created, update"
  end
end
