class CreatePatternTags < ActiveRecord::Migration[6.1]
  def change
    create_table :pattern_tags do |t|
      t.integer :pattern_id
      t.integer :tag_id

      t.timestamps
    end
  end
end
