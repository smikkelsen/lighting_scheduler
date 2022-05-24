class CreateZoneSets < ActiveRecord::Migration[6.1]
  def change
    create_table :zone_sets do |t|
      t.string :name

      t.timestamps
    end
  end
end
