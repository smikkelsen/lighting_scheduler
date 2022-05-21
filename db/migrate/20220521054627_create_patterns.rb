class CreatePatterns < ActiveRecord::Migration[6.1]
  def change
    create_table :patterns do |t|
      t.string :folder
      t.string :name
      t.boolean :custom

      t.timestamps
    end
  end
end
