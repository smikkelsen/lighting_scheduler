ActiveAdmin.register Pattern do
  config.comments = false

  index do
    column :folder
    column :name
    column :custom
    column 'Preview' do |pattern|
      render 'patterns/pattern_preview', { pattern: pattern }
    end
    actions
  end

  show do
    attributes_table do
      row 'Name' do |p|
        [p.folder, p.name].join('/')
      end
      row :custom
    end

    panel 'Preview' do
      render 'patterns/pattern_preview', { pattern: pattern }
    end

  end

  form do |f|
    f.inputs 'Details' do
      f.input :name
      f.input :tags, as: :searchable_select, multiple: true, collection: Tag.all.map { |t| [t.name, t.id] }
    end
    f.actions
  end
  permit_params do
    [:name, tag_ids: []]
  end
  action_item :update_cached, only: :index do
    link_to 'Update Cached', update_cached_patterns_path, method: :post
  end

  collection_action :update_cached, method: :post do
    Pattern.update_cached
    Pattern.cache_pattern_data(true)
    redirect_to collection_path, notice: "Patterns Updated!"
  end

  member_action :activate, method: :post do
    resource.activate
    redirect_back fallback_location: pattern_path(resource), notice: "Activated '#{resource&.name}' pattern"
  end

end
