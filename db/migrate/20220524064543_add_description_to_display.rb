class AddDescriptionToDisplay < ActiveRecord::Migration[6.1]
  def change
    add_column :displays, :description, :text
  end
end
