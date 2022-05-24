class DropDisplayPatternZone < ActiveRecord::Migration[6.1]
  def change
    drop_table :display_pattern_zones
  end
end
