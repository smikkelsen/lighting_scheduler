class CreateDisplayPatterns < ActiveRecord::Migration[6.1]
  def change
    create_table :display_patterns do |t|
      t.integer :display_id
      t.integer :pattern_id

      t.timestamps
    end
  end
end
