class CreateZones < ActiveRecord::Migration[6.1]
  def change
    create_table :zones do |t|
      t.string :name
      t.integer :pixel_count

      t.timestamps
    end
  end
end
