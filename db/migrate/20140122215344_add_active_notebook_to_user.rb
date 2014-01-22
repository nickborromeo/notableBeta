class AddActiveNotebookToUser < ActiveRecord::Migration
  def change
    add_column :users, :active_notebook, :integer
  end
end
