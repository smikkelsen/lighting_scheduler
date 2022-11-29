class AddDefaultZoneSetToZoneSet < ActiveRecord::Migration[6.1]
  def change
    add_column :zone_sets, :default_zone_set, :boolean, default: false
  end
end
