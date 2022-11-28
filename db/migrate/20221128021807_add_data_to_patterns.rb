class AddDataToPatterns < ActiveRecord::Migration[6.1]
  def change
    add_column :patterns, :data, :jsonb
  end
end
