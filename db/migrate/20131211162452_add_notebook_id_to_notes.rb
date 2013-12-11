class AddNotebookIdToNotes < ActiveRecord::Migration
  def change
    add_column :notes, :notebook_id, :integer
  end
end
