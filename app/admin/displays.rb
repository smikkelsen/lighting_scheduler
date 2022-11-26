ActiveAdmin.register Display do

  form do |f|
    f.inputs 'Details' do
      f.input :name
      f.input :description
      f.input :zone_set, as: :searchable_select
      f.input :tags, as: :searchable_select, multiple: true, collection: Tag.all.map {|t| [t.name, t.id]}
    end
    f.inputs 'Pattern Configuration' do
      f.has_many :display_patterns, heading: false,
                 allow_destroy: true,
                 new_record: true do |a|
        a.input :pattern, as: :searchable_select
        a.input :zones, as: :searchable_select, multiple: true, collection: Zone.in_set.order(:zone_set_id).map {|z| ["#{z.zone_set&.name}: #{z.name}", z.id]}
      end
    end
    f.actions
  end
  #
  permit_params do
    [:name, :workflow_state, :zone_set_id, :description, tag_ids: [], display_patterns_attributes: [:id, :pattern_id, :_destroy, zones: []]]
  end

  action_item :activate_display, only: :show do
    link_to 'Activate Display', activate_display_path(resource), method: :post
  end

  member_action :activate, method: :post do
    resource.activate
    redirect_back fallback_location: display_path(resource), notice: "Activated '#{resource&.name}' display"
  end
end
