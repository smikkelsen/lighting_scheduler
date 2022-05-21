class CreateDisplays < ActiveRecord::Migration[6.1]
  def change
    create_table :displays do |t|
      t.string :name

      t.timestamps
    end
  end
end
