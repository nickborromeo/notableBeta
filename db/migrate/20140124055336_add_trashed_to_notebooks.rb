class AddTrashedToNotebooks < ActiveRecord::Migration
  def change
    add_column :notebooks, :trashed, :boolean, :default => false
  end
end
