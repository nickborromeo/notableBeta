class AddGuidToNotebooks < ActiveRecord::Migration
  def change
    add_column :notebooks, :guid, :string
  end
end
