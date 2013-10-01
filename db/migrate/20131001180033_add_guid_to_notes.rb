class AddGuidToNotes < ActiveRecord::Migration
  def change
    add_column :notes, :guid, :string
  end
end
