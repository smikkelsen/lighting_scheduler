class CreateDisplayPatternZones < ActiveRecord::Migration[6.1]
  def change
    create_table :display_pattern_zones do |t|
      t.integer :display_pattern_id
      t.integer :zone_id

      t.timestamps
    end
  end
end
