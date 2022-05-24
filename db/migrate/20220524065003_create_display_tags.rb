class CreateDisplayTags < ActiveRecord::Migration[6.1]
  def change
    create_table :display_tags do |t|
      t.integer :display_id
      t.integer :tag_id

      t.timestamps
    end
  end
end
