class AddFieldsToZone < ActiveRecord::Migration[6.1]
  def change
    add_column :zones, :port_map, :jsonb
    add_column :zones, :zone_set_id, :integer
    add_column :zones, :uuid, :string
  end
end
