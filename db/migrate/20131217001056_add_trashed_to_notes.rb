class AddTrashedToNotes < ActiveRecord::Migration
  def change
    add_column :notes, :trashed, :boolean, :default => false
  end
end
