ActiveAdmin.register Display do

  show do
    attributes_table do
      row :name
      row :zone_set
      row :workflow_state
      row :description
    end

    panel "Display Patterns" do
      table_for resource.display_patterns do
        column :pattern
        column 'Colors' do |dp|
          render 'patterns/pattern_preview', { pattern: dp.pattern }
        end
        column 'Zones' do |dp|
          resource.parameterize_zones(dp.zones)
        end
      end
    end
  end

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
        a.input :pattern, as: :searchable_select, collection: Pattern.all.order('folder, name').map {|p| ["#{p.folder}/#{p.name}", p.id]}
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
