ActiveAdmin.register Zone do
  config.comments = false

  # Configure filters
  filter :name
  filter :zone_set
  filter :pixel_count
  filter :uuid
  filter :created_at
  filter :updated_at

  # permit_params do
  #   permitted = [:name, :pixel_count, :port_map, :zone_set_id, :uuid]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  action_item :update_cached, only: :index do
    link_to 'Update Cached' , update_cached_zones_path, method: :post
  end

  collection_action :update_cached, method: :post do
    Zone.update_cached
    redirect_to collection_path, notice: "Zones Updated!"
  end
end
