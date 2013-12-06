class AddFreshToNotes < ActiveRecord::Migration
  def change
    add_column :notes, :fresh, :boolean
  end
end
