ActiveAdmin.register Tag do
  config.comments = false

  show do
    attributes_table do
      row :name
    end

    panel "Displays" do
      table_for tag.displays.active do
        column 'Name' do |display|
          link_to display.name, display_path(display)
        end
        column 'Actions' do |display|
          link_to 'Activate', activate_display_path(display), method: :post
        end
      end
    end

    panel "Patterns" do
      table_for tag.patterns do
        column 'Name' do |pattern|
          link_to pattern.name, pattern_path(pattern)
        end
        column 'Actions' do |pattern|
          link_to 'Activate', activate_pattern_path(pattern), method: :post
        end
      end
    end
  end
  
  permit_params { [:name] }

  action_item :activate_random_display, only: :show do
    link_to 'Activate Random Display', activate_random_display_tag_path(tag), method: :post
  end
  member_action :activate_random_display, method: :post do
    display = resource.activate_random_display
    notice = display ? "Activated #{display.name}" : "No display chosen"
    redirect_to tag_path(resource), notice: notice
  end
end
