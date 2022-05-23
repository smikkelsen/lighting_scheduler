class AddWorkflowStateToDisplays < ActiveRecord::Migration[6.1]
  def change
    add_column :displays, :workflow_state, :string
  end
end
