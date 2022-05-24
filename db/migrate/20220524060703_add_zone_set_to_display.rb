class AddZoneSetToDisplay < ActiveRecord::Migration[6.1]
  def change
    add_column :displays, :zone_set_id, :integer
  end
end
