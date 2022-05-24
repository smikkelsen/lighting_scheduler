class AddZonesToDisplayPatterns < ActiveRecord::Migration[6.1]
  def change
    add_column :display_patterns, :zones, :jsonb
  end
end
