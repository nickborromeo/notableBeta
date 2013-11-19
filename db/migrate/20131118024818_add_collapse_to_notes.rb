class AddCollapseToNotes < ActiveRecord::Migration
  def change
    add_column :notes, :collapsed, :boolean
  end
end
